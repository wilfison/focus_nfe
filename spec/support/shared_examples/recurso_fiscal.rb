# frozen_string_literal: true

RSpec.shared_examples "um recurso emitível" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:dados) { { "natureza_operacao" => "Venda" } }
  let(:processando) { '{"status":"processando_autorizacao"}' }

  let(:json) { { "Content-Type" => "application/json" } }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_recurso(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#emitir" do
    before { stub_recurso(:post, "#{caminho}?ref=pedido-42", status: 202, body: processando) }

    it "envia POST em /v2/#{caminho}?ref= com o JSON dos dados" do
      recurso.emitir(ref: "pedido-42", dados: dados)

      url = "#{homologacao}/v2/#{caminho}?ref=pedido-42"

      expect(a_request(:post, url).with(body: JSON.generate(dados))).to have_been_made
    end

    it "devolve um Documento processando com a ref", :aggregate_failures do
      doc = recurso.emitir(ref: "pedido-42", dados: dados)

      expect(doc).to be_a(FocusNfe::Modelos::Documento)
      expect(doc).to be_processando
      expect(doc.ref).to eq("pedido-42")
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_recurso(:post, "#{caminho}?ref=pedido-42", host: producao, status: 202, body: processando)

        recurso.emitir(ref: "pedido-42", dados: dados)

        expect(stub).to have_been_requested
      end
    end

    it "propaga erro tipado da API (422)" do
      stub_recurso(:post, "#{caminho}?ref=pedido-42", status: 422, body: '{"erros":[]}')

      expect { recurso.emitir(ref: "pedido-42", dados: dados) }.to raise_error(FocusNfe::Errors::ValidationError)
    end

    it "rejeita ref inválida sem requisição", :aggregate_failures do
      expect { recurso.emitir(ref: "pedido 42", dados: dados) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}")).not_to have_been_made
    end
  end
end

RSpec.shared_examples "um recurso consultável" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :homologacao) }
  let(:json) { { "Content-Type" => "application/json" } }

  def homologacao = "https://homologacao.focusnfe.com.br"

  def stub_recurso(verb, path, status: 200, body: "{}")
    stub_request(verb, "#{homologacao}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#consultar" do
    it "faz GET em /v2/#{caminho}/{ref} e devolve o Documento autorizado", :aggregate_failures do
      stub_recurso(:get, "#{caminho}/pedido-42", body: '{"status":"autorizado","chave_nfe":"3520"}')
      doc = recurso.consultar("pedido-42")

      expect(doc).to be_autorizado
      expect(doc.chave_nfe).to eq("3520")
    end

    it "envia ?completa=1 quando completa: true" do
      stub = stub_recurso(:get, "#{caminho}/pedido-42?completa=1", body: '{"status":"autorizado"}')

      recurso.consultar("pedido-42", completa: true)

      expect(stub).to have_been_requested
    end

    it "não envia completa por padrão" do
      stub = stub_recurso(:get, "#{caminho}/pedido-42", body: '{"status":"autorizado"}')

      recurso.consultar("pedido-42")

      expect(stub).to have_been_requested
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.consultar("pedido 42") }.to raise_error(ArgumentError)
    end
  end
end

RSpec.shared_examples "um recurso visualizável" do |caminho_previa|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:dados) { { "natureza_operacao" => "Venda" } }
  let(:pdf) { { "Content-Type" => "application/pdf" } }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_previa(caminho_previa, host: homologacao, status: 200, body: "%PDF-1.4 previa")
    stub_request(:post, "#{host}/v2/#{caminho_previa}").to_return(status: status, body: body, headers: pdf)
  end

  describe "#previa" do
    it "faz POST em /v2/#{caminho_previa} com o JSON dos dados e devolve os bytes do PDF", :aggregate_failures do
      stub_previa(caminho_previa)
      bytes = recurso.previa(dados: dados)

      url = "#{homologacao}/v2/#{caminho_previa}"

      expect(a_request(:post, url).with(body: JSON.generate(dados))).to have_been_made
      expect(bytes).to eq("%PDF-1.4 previa")
    end

    it "não valida por padrão" do
      stub_previa(caminho_previa)

      recurso.previa(dados: {})

      expect(a_request(:post, "#{homologacao}/v2/#{caminho_previa}")).to have_been_made
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_previa(caminho_previa, host: producao)

        recurso.previa(dados: dados)

        expect(stub).to have_been_requested
      end
    end
  end
end

RSpec.shared_examples "um recurso corrigível" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:correcao) { "corrigindo o endereco de entrega do destinatario" }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_recurso(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#corrigir" do
    let(:autorizada) { '{"status":"autorizado","numero_carta_correcao":"1","caminho_xml_carta_correcao":"/cce.xml"}' }

    before { stub_recurso(:post, "#{caminho}/pedido-42/carta_correcao", body: autorizada) }

    it "envia POST em /v2/#{caminho}/{ref}/carta_correcao só com a correção" do
      recurso.corrigir("pedido-42", correcao: correcao)

      url = "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao"

      expect(a_request(:post, url).with(body: JSON.generate(correcao: correcao))).to have_been_made
    end

    it "devolve um Documento com os dados da carta de correção", :aggregate_failures do
      doc = recurso.corrigir("pedido-42", correcao: correcao)

      expect(doc).to be_a(FocusNfe::Modelos::Documento)
      expect(doc).to be_autorizado
      expect(doc.numero_carta_correcao).to eq("1")
      expect(doc.caminho_xml_carta_correcao).to eq("/cce.xml")
    end

    it "inclui data_evento no corpo quando informado" do
      recurso.corrigir("pedido-42", correcao: correcao, data_evento: "2026-06-13T10:00:00-03:00")

      url = "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao"
      corpo = JSON.generate(correcao: correcao, data_evento: "2026-06-13T10:00:00-03:00")

      expect(a_request(:post, url).with(body: corpo)).to have_been_made
    end

    it "rejeita correção com menos de 15 caracteres sem requisição", :aggregate_failures do
      expect { recurso.corrigir("pedido-42", correcao: "curta") }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao")).not_to have_been_made
    end

    it "rejeita correção com mais de 1000 caracteres sem requisição", :aggregate_failures do
      expect { recurso.corrigir("pedido-42", correcao: "a" * 1001) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao")).not_to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.corrigir("pedido 42", correcao: correcao) }.to raise_error(ArgumentError)
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_recurso(:post, "#{caminho}/pedido-42/carta_correcao", host: producao, body: autorizada)

        recurso.corrigir("pedido-42", correcao: correcao)

        expect(stub).to have_been_requested
      end
    end
  end
end

RSpec.shared_examples "um recurso corrigível por campo" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_recurso(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#corrigir" do
    let(:autorizada) { '{"status":"autorizado","numero_carta_correcao":"1","caminho_xml":"/cce.xml"}' }

    before { stub_recurso(:post, "#{caminho}/pedido-42/carta_correcao", body: autorizada) }

    it "envia POST em /v2/#{caminho}/{ref}/carta_correcao com o campo e o valor" do
      recurso.corrigir("pedido-42", campo_corrigido: "observacoes", valor_corrigido: "Nova observação")

      url = "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao"
      corpo = JSON.generate(campo_corrigido: "observacoes", valor_corrigido: "Nova observação")

      expect(a_request(:post, url).with(body: corpo)).to have_been_made
    end

    it "devolve um Documento com os dados da carta de correção", :aggregate_failures do
      doc = recurso.corrigir("pedido-42", campo_corrigido: "observacoes", valor_corrigido: "Nova observação")

      expect(doc).to be_a(FocusNfe::Modelos::Documento)
      expect(doc).to be_autorizado
      expect(doc.numero_carta_correcao).to eq("1")
    end

    it "inclui grupo, número do item e campo_api no corpo quando informados" do
      opcionais = { grupo_corrigido: "cargas", numero_item_grupo_corrigido: "1", campo_api: 0 }
      recurso.corrigir("pedido-42", campo_corrigido: "peso", valor_corrigido: "1000", **opcionais)

      url = "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao"
      corpo = JSON.generate(campo_corrigido: "peso", valor_corrigido: "1000", **opcionais)

      expect(a_request(:post, url).with(body: corpo)).to have_been_made
    end

    it "rejeita campo_corrigido vazio sem requisição", :aggregate_failures do
      expect { recurso.corrigir("pedido-42", campo_corrigido: "", valor_corrigido: "x") }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao")).not_to have_been_made
    end

    it "rejeita valor_corrigido vazio sem requisição", :aggregate_failures do
      expect do
        recurso.corrigir("pedido-42", campo_corrigido: "peso", valor_corrigido: "")
      end.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/pedido-42/carta_correcao")).not_to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect do
        recurso.corrigir("pedido 42", campo_corrigido: "peso", valor_corrigido: "1000")
      end.to raise_error(ArgumentError)
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_recurso(:post, "#{caminho}/pedido-42/carta_correcao", host: producao, body: autorizada)

        recurso.corrigir("pedido-42", campo_corrigido: "observacoes", valor_corrigido: "Nova observação")

        expect(stub).to have_been_requested
      end
    end
  end
end

RSpec.shared_examples "um recurso inutilizável" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:dados) do
    { cnpj: "12345678000190", serie: "1", numero_inicial: "10", numero_final: "20",
      justificativa: "erro de digitacao no sistema" }
  end

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_recurso(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#inutilizar" do
    let(:autorizada) { '{"status":"autorizado","protocolo_sefaz":"135200"}' }

    before { stub_recurso(:post, "#{caminho}/inutilizacao", body: autorizada) }

    it "envia POST em /v2/#{caminho}/inutilizacao com o JSON dos campos" do
      recurso.inutilizar(**dados)

      url = "#{homologacao}/v2/#{caminho}/inutilizacao"

      expect(a_request(:post, url).with(body: JSON.generate(dados))).to have_been_made
    end

    it "devolve uma Inutilizacao autorizada com o protocolo", :aggregate_failures do
      inut = recurso.inutilizar(**dados)

      expect(inut).to be_a(FocusNfe::Modelos::Inutilizacao)
      expect(inut).to be_autorizado
      expect(inut.protocolo).to eq("135200")
    end

    it "rejeita justificativa com menos de 15 caracteres sem requisição", :aggregate_failures do
      expect { recurso.inutilizar(**dados, justificativa: "curta") }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).not_to have_been_made
    end

    it "rejeita numero_inicial maior que numero_final sem requisição", :aggregate_failures do
      expect { recurso.inutilizar(**dados, numero_inicial: "20", numero_final: "10") }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).not_to have_been_made
    end

    it "aceita faixa de um único número (inicial igual a final)" do
      recurso.inutilizar(**dados, numero_inicial: "10", numero_final: "10")

      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).to have_been_made
    end

    it "aceita numero_inicial e numero_final como inteiros" do
      recurso.inutilizar(**dados, numero_inicial: 10, numero_final: 20)

      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).to have_been_made
    end

    it "rejeita numero_inicial ausente sem requisição", :aggregate_failures do
      expect { recurso.inutilizar(**dados, numero_inicial: nil) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).not_to have_been_made
    end

    it "rejeita numero_final não numérico sem requisição", :aggregate_failures do
      expect { recurso.inutilizar(**dados, numero_final: "abc") }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/#{caminho}/inutilizacao")).not_to have_been_made
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_recurso(:post, "#{caminho}/inutilizacao", host: producao, body: autorizada)

        recurso.inutilizar(**dados)

        expect(stub).to have_been_requested
      end
    end
  end

  describe "#consultar_inutilizacoes" do
    it "faz GET em /v2/#{caminho}/inutilizacoes e devolve Inutilizacoes", :aggregate_failures do
      corpo = '[{"status":"autorizado","protocolo_sefaz":"1"},{"status":"autorizado","protocolo_sefaz":"2"}]'
      stub_recurso(:get, "#{caminho}/inutilizacoes", body: corpo)

      lista = recurso.consultar_inutilizacoes

      expect(lista.map(&:protocolo)).to eq(%w[1 2])
      expect(lista).to all(be_a(FocusNfe::Modelos::Inutilizacao))
    end

    it "envia os filtros como query string" do
      stub = stub_recurso(:get, "#{caminho}/inutilizacoes?cnpj=123&serie=1", body: "[]")

      recurso.consultar_inutilizacoes(cnpj: "123", serie: "1")

      expect(stub).to have_been_requested
    end

    it "devolve lista vazia quando o corpo não é um array" do
      stub_recurso(:get, "#{caminho}/inutilizacoes", body: "{}")

      expect(recurso.consultar_inutilizacoes).to eq([])
    end
  end
end

RSpec.shared_examples "um recurso cancelável" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :homologacao) }
  let(:json) { { "Content-Type" => "application/json" } }

  def homologacao = "https://homologacao.focusnfe.com.br"

  def stub_recurso(verb, path, status: 200, body: "{}")
    stub_request(verb, "#{homologacao}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#cancelar" do
    it "faz DELETE em /v2/#{caminho}/{ref} com a justificativa no corpo", :aggregate_failures do
      stub_recurso(:delete, "#{caminho}/pedido-42", body: '{"status":"cancelado"}')
      doc = recurso.cancelar("pedido-42", justificativa: "erro")
      enviado = a_request(:delete, "#{homologacao}/v2/#{caminho}/pedido-42").with(body: '{"justificativa":"erro"}')

      expect(doc).to be_cancelado
      expect(enviado).to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.cancelar("pedido 42", justificativa: "x") }.to raise_error(ArgumentError)
    end
  end
end
