# frozen_string_literal: true

RSpec.shared_examples "um recurso emitível" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token: "tok", environment: environment) }
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

  let(:client) { FocusNfe::Client.new(token: "tok", environment: :homologacao) }
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

RSpec.shared_examples "um recurso cancelável" do |caminho|
  subject(:recurso) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token: "tok", environment: :homologacao) }
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
