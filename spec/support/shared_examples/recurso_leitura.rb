# frozen_string_literal: true

RSpec.shared_context "com recurso conectado" do
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :homologacao) }
  let(:json) { { "Content-Type" => "application/json" } }

  def homologacao = "https://homologacao.focusnfe.com.br"

  def stub_get(path, query: nil, status: 200, body: "{}", headers: nil)
    stub = stub_request(:get, "#{homologacao}/v2/#{path}")
    stub = stub.with(query: query) if query
    stub.to_return(status: status, body: body, headers: headers || json)
  end

  def stub_envio(verbo, path, query: nil, body: nil, resposta: "{}")
    stub = stub_request(verbo, "#{homologacao}/v2/#{path}")
    stub = stub.with(query: query) if query
    stub = stub.with(body: body) if body
    stub.to_return(status: 200, body: resposta, headers: json)
  end
end

RSpec.shared_examples "um recurso listável" do |caminho|
  include_context "com recurso conectado"

  describe "#listar" do
    it "faz GET em /v2/#{caminho} e devolve uma Pagina" do
      stub_get(caminho, body: "[]")

      expect(recurso.listar).to be_a(FocusNfe::Modelos::Pagina)
    end

    it "repassa os filtros como query string" do
      stub = stub_get(caminho, query: { cnpj: "123" }, body: "[]")

      recurso.listar(cnpj: "123")

      expect(stub).to have_been_requested
    end

    it "expõe total e versao_maxima dos headers", :aggregate_failures do
      headers = json.merge("X-Total-Count" => "2", "X-Max-Version" => "7")
      stub_get(caminho, body: "[]", headers: headers)

      expect(recurso.listar).to have_attributes(total: 2, versao_maxima: 7)
    end
  end
end

RSpec.shared_examples "um recurso baixável" do |caminho|
  include_context "com recurso conectado"

  describe "#download" do
    it "baixa o PDF seguindo o 302 para a URL pré-assinada" do
      origem = "#{homologacao}/v2/#{caminho}/CHAVE.pdf"
      destino = "https://arquivos.focusnfe.com.br/danfe.pdf"
      stub_request(:get, origem).to_return(status: 302, headers: { "Location" => destino })
      stub_request(:get, destino).to_return(status: 200, body: "%PDF")

      expect(recurso.download_pdf("CHAVE")).to eq("%PDF")
    end

    it "baixa o XML cru" do
      stub_get("#{caminho}/CHAVE.xml", body: "<nfe/>", headers: { "Content-Type" => "application/xml" })

      expect(recurso.download_xml("CHAVE")).to eq("<nfe/>")
    end

    it "baixa o JSON cru, sem parsear (raw_body)" do
      stub_get("#{caminho}/CHAVE.json", body: '{"a":1}')

      expect(recurso.download_json("CHAVE")).to eq('{"a":1}')
    end

    it "escapa o formato, sem injetar query no path" do
      stub_request(:get, /focusnfe/).to_return(status: 200, body: "ok", headers: json)

      recurso.download("CHAVE", formato: "pdf?x=1")

      enviado = a_request(:get, /focusnfe/)
                .with { |req| req.uri.query.nil? && req.uri.path.include?("CHAVE.pdf%3F") }
      expect(enviado).to have_been_made
    end
  end
end

RSpec.shared_examples "um recurso localizável" do |caminho|
  include_context "com recurso conectado"

  describe "#consultar" do
    it "faz GET em /v2/#{caminho}/{id} e devolve o corpo cru" do
      stub_get("#{caminho}/123", body: '{"codigo":"123"}')

      expect(recurso.consultar("123")).to eq("codigo" => "123")
    end
  end
end

RSpec.shared_examples "um recurso notificável" do |caminho|
  include_context "com recurso conectado"

  describe "#reenviar_hook" do
    it "faz POST em /v2/#{caminho}/{id}/hook" do
      stub = stub_envio(:post, "#{caminho}/123/hook")

      recurso.reenviar_hook("123")

      expect(stub).to have_been_requested
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.reenviar_hook("pedido 42") }.to raise_error(ArgumentError)
    end
  end
end

RSpec.shared_examples "um recurso enviável por email" do |caminho|
  include_context "com recurso conectado"

  describe "#enviar_email" do
    it "faz POST em /v2/#{caminho}/{ref}/email com a lista de emails" do
      stub = stub_envio(:post, "#{caminho}/pedido-42/email", body: { emails: ["a@x.com", "b@x.com"] })

      recurso.enviar_email("pedido-42", emails: ["a@x.com", "b@x.com"])

      expect(stub).to have_been_requested
    end

    it "devolve o corpo cru da resposta" do
      stub_envio(:post, "#{caminho}/pedido-42/email", resposta: '{"status":"enviado"}')

      expect(recurso.enviar_email("pedido-42", emails: ["a@x.com"])).to eq("status" => "enviado")
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.enviar_email("pedido 42", emails: ["a@x.com"]) }.to raise_error(ArgumentError)
    end

    it "rejeita lista de emails vazia sem requisição", :aggregate_failures do
      expect { recurso.enviar_email("pedido-42", emails: []) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/email")).not_to have_been_made
    end

    it "rejeita mais de 10 emails sem requisição", :aggregate_failures do
      emails = Array.new(11) { |i| "e#{i}@x.com" }

      expect { recurso.enviar_email("pedido-42", emails: emails) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/email")).not_to have_been_made
    end
  end
end

RSpec.shared_examples "um recurso conciliável" do |caminho|
  include_context "com recurso conectado"

  let(:detalhes) { [{ "forma_pagamento" => "01", "valor_pagamento" => 1, "data_pagamento" => "2025-02-10" }] }

  describe "#registrar_econf" do
    it "faz POST em /v2/#{caminho}/{ref}/econf com detalhes_pagamento", :aggregate_failures do
      stub_envio(:post, "#{caminho}/pedido-42/econf", body: { detalhes_pagamento: detalhes })

      doc = recurso.registrar_econf("pedido-42", detalhes_pagamento: detalhes)

      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/econf")
        .with(body: JSON.generate(detalhes_pagamento: detalhes))).to have_been_made
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.registrar_econf("pedido 42", detalhes_pagamento: detalhes) }.to raise_error(ArgumentError)
    end
  end

  describe "#consultar_econf" do
    it "faz GET em /v2/#{caminho}/{ref}/econf/{protocolo}" do
      stub = stub_get("#{caminho}/pedido-42/econf/335250000000445")

      recurso.consultar_econf("pedido-42", "335250000000445")

      expect(stub).to have_been_requested
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.consultar_econf("pedido 42", "1") }.to raise_error(ArgumentError)
    end
  end

  describe "#cancelar_econf" do
    it "faz DELETE em /v2/#{caminho}/{ref}/econf/{protocolo}" do
      stub = stub_envio(:delete, "#{caminho}/pedido-42/econf/335250000000445")

      recurso.cancelar_econf("pedido-42", "335250000000445")

      expect(stub).to have_been_requested
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.cancelar_econf("pedido 42", "1") }.to raise_error(ArgumentError)
    end
  end
end

RSpec.shared_examples "um recurso removível" do |caminho|
  include_context "com recurso conectado"

  describe "#excluir" do
    it "faz DELETE em /v2/#{caminho}/{id}" do
      stub = stub_envio(:delete, "#{caminho}/123")

      recurso.excluir("123")

      expect(stub).to have_been_requested
    end
  end
end
