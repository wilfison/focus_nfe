# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfe do
  subject(:nfe) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:dados) { { "natureza_operacao" => "Venda" } }
  let(:processando) { '{"status":"processando_autorizacao"}' }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_nfe(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  describe "#emitir" do
    before { stub_nfe(:post, "nfe?ref=pedido-42", status: 202, body: processando) }

    it "envia POST em /v2/nfe?ref= com o JSON dos dados" do
      nfe.emitir(ref: "pedido-42", dados: dados)

      expect(a_request(:post, "#{homologacao}/v2/nfe?ref=pedido-42").with(body: JSON.generate(dados))).to have_been_made
    end

    it "devolve um Documento processando com a ref", :aggregate_failures do
      doc = nfe.emitir(ref: "pedido-42", dados: dados)

      expect(doc).to be_a(FocusNfe::Modelos::Documento)
      expect(doc).to be_processando
      expect(doc.ref).to eq("pedido-42")
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_nfe(:post, "nfe?ref=pedido-42", host: producao, status: 202, body: processando)

        nfe.emitir(ref: "pedido-42", dados: dados)

        expect(stub).to have_been_requested
      end
    end

    it "propaga erro tipado da API (422)" do
      stub_nfe(:post, "nfe?ref=pedido-42", status: 422, body: '{"erros":[]}')

      expect { nfe.emitir(ref: "pedido-42", dados: dados) }.to raise_error(FocusNfe::Errors::ValidationError)
    end

    it "rejeita ref inválida sem requisição", :aggregate_failures do
      expect { nfe.emitir(ref: "pedido 42", dados: dados) }.to raise_error(ArgumentError)
      expect(a_request(:post, "#{homologacao}/v2/nfe")).not_to have_been_made
    end
  end

  describe "#consultar" do
    it "faz GET em /v2/nfe/{ref} e devolve o Documento autorizado", :aggregate_failures do
      stub_nfe(:get, "nfe/pedido-42", body: '{"status":"autorizado","chave_nfe":"3520"}')
      doc = nfe.consultar("pedido-42")

      expect(doc).to be_autorizado
      expect(doc.chave_nfe).to eq("3520")
    end

    it "envia ?completa=1 quando completa: true" do
      stub = stub_nfe(:get, "nfe/pedido-42?completa=1", body: '{"status":"autorizado"}')

      nfe.consultar("pedido-42", completa: true)

      expect(stub).to have_been_requested
    end

    it "não envia completa por padrão" do
      stub = stub_nfe(:get, "nfe/pedido-42", body: '{"status":"autorizado"}')

      nfe.consultar("pedido-42")

      expect(stub).to have_been_requested
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.consultar("pedido 42") }.to raise_error(ArgumentError)
    end
  end

  describe "#cancelar" do
    it "faz DELETE em /v2/nfe/{ref} com a justificativa no corpo", :aggregate_failures do
      stub_nfe(:delete, "nfe/pedido-42", body: '{"status":"cancelado"}')
      doc = nfe.cancelar("pedido-42", justificativa: "erro")
      enviado = a_request(:delete, "#{homologacao}/v2/nfe/pedido-42").with(body: '{"justificativa":"erro"}')

      expect(doc).to be_cancelado
      expect(enviado).to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.cancelar("pedido 42", justificativa: "x") }.to raise_error(ArgumentError)
    end
  end
end
