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

  describe "#baixar" do
    it "baixa o PDF seguindo o 302 para a URL pré-assinada" do
      origem = "#{homologacao}/v2/#{caminho}/CHAVE.pdf"
      destino = "https://arquivos.focusnfe.com.br/danfe.pdf"
      stub_request(:get, origem).to_return(status: 302, headers: { "Location" => destino })
      stub_request(:get, destino).to_return(status: 200, body: "%PDF")

      expect(recurso.baixar_pdf("CHAVE")).to eq("%PDF")
    end

    it "baixa o XML cru" do
      stub_get("#{caminho}/CHAVE.xml", body: "<nfe/>", headers: { "Content-Type" => "application/xml" })

      expect(recurso.baixar_xml("CHAVE")).to eq("<nfe/>")
    end

    it "baixa o JSON cru, sem parsear (raw_body)" do
      stub_get("#{caminho}/CHAVE.json", body: '{"a":1}')

      expect(recurso.baixar_json("CHAVE")).to eq('{"a":1}')
    end

    it "escapa o formato, sem injetar query no path" do
      stub_request(:get, /focusnfe/).to_return(status: 200, body: "ok", headers: json)

      recurso.baixar("CHAVE", formato: "pdf?x=1")

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
