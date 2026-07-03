# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfe do
  subject(:nfe) { described_class.new(client.connection) }

  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: environment) }
  let(:environment) { :homologacao }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:dados) { { "natureza_operacao" => "Venda" } }
  let(:processando) { '{"status":"processando_autorizacao"}' }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def stub_nfe(verb, path, host: homologacao, status: 200, body: "{}")
    stub_request(verb, "#{host}/v2/#{path}").to_return(status: status, body: body, headers: json)
  end

  it_behaves_like "um recurso corrigível", "nfe"
  it_behaves_like "um recurso inutilizável", "nfe"
  it_behaves_like "um recurso visualizável", "nfe/danfe"
  it_behaves_like "um recurso notificável", "nfe"
  it_behaves_like "um recurso enviável por email", "nfe"
  it_behaves_like "um recurso conciliável", "nfe"

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

  describe "#importar" do
    let(:xml) { "<nfeProc><NFe/></nfeProc>" }

    it "faz POST em /v2/nfe/importacao com o XML cru e Content-Type application/xml" do
      stub_nfe(:post, "nfe/importacao", body: '{"status":"processando_autorizacao"}')
      nfe.importar(xml)

      enviado = a_request(:post, "#{homologacao}/v2/nfe/importacao")
                .with(body: xml, headers: { "Content-Type" => "application/xml" })
      expect(enviado).to have_been_made
    end

    it "envia ?ref= quando a referência é informada", :aggregate_failures do
      stub = stub_nfe(:post, "nfe/importacao?ref=pedido-42", body: '{"status":"processando_autorizacao"}')

      doc = nfe.importar(xml, ref: "pedido-42")

      expect(stub).to have_been_requested
      expect(doc.ref).to eq("pedido-42")
    end

    it "omite ref por padrão" do
      stub = stub_nfe(:post, "nfe/importacao", body: "{}")

      nfe.importar(xml)

      expect(stub).to have_been_requested
    end

    context "quando o ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_nfe(:post, "nfe/importacao", host: producao, body: "{}")

        nfe.importar(xml)

        expect(stub).to have_been_requested
      end
    end
  end

  describe "#emitir_evento" do
    let(:corpo) do
      { tipo_evento: "prorrogacao_suspensao_icms",
        itens_prorrogacao_suspensao_icms: [{ numero_item: "1", quantidade_item: 1 }] }
    end

    it "faz POST em /v2/nfe/{ref}/evento com tipo_evento e itens", :aggregate_failures do
      stub_nfe(:post, "nfe/pedido-42/evento")

      doc = nfe.emitir_evento("pedido-42", **corpo)

      enviado = a_request(:post, "#{homologacao}/v2/nfe/pedido-42/evento").with(body: JSON.generate(corpo))
      expect(enviado).to have_been_made
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.emitir_evento("pedido 42", tipo_evento: "x") }.to raise_error(ArgumentError)
    end
  end

  describe "#cancelar_evento" do
    it "faz DELETE em /v2/nfe/{ref}/evento com tipo_evento no corpo", :aggregate_failures do
      stub_nfe(:delete, "nfe/pedido-42/evento")

      nfe.cancelar_evento("pedido-42", tipo_evento: "prorrogacao_suspensao_icms")

      enviado = a_request(:delete, "#{homologacao}/v2/nfe/pedido-42/evento")
                .with(body: JSON.generate(tipo_evento: "prorrogacao_suspensao_icms"))
      expect(enviado).to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.cancelar_evento("pedido 42", tipo_evento: "x") }.to raise_error(ArgumentError)
    end
  end

  describe "#registrar_ator_interessado" do
    it "faz POST em /v2/nfe/{ref}/ator_interessado com o CNPJ e a autorização", :aggregate_failures do
      stub_nfe(:post, "nfe/pedido-42/ator_interessado")

      nfe.registrar_ator_interessado("pedido-42", permite_autorizacao_terceiros: true, cnpj: "12345678000190")

      corpo = JSON.generate(permite_autorizacao_terceiros: true, cnpj: "12345678000190")
      expect(a_request(:post, "#{homologacao}/v2/nfe/pedido-42/ator_interessado").with(body: corpo))
        .to have_been_made
    end

    it "omite cpf e cnpj quando não informados" do
      stub_nfe(:post, "nfe/pedido-42/ator_interessado")

      nfe.registrar_ator_interessado("pedido-42", permite_autorizacao_terceiros: false)

      corpo = JSON.generate(permite_autorizacao_terceiros: false)
      expect(a_request(:post, "#{homologacao}/v2/nfe/pedido-42/ator_interessado").with(body: corpo))
        .to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.registrar_ator_interessado("pedido 42", permite_autorizacao_terceiros: true) }
        .to raise_error(ArgumentError)
    end
  end

  describe "#registrar_insucesso_entrega" do
    let(:insucesso) do
      { data_tentativa_entrega: "2024-07-24T10:30:56-03:00", motivo_insucesso: 4,
        hash_tentativa_entrega: "yzmPGyT1YM5KqilP56w+oPlVkx8=", justificativa_insucesso: "endereço incorreto" }
    end

    it "faz POST em /v2/nfe/{ref}/insucesso_entrega com os campos obrigatórios e opcionais" do
      stub_nfe(:post, "nfe/pedido-42/insucesso_entrega")
      nfe.registrar_insucesso_entrega("pedido-42", **insucesso)

      enviado = a_request(:post, "#{homologacao}/v2/nfe/pedido-42/insucesso_entrega")
                .with(body: JSON.generate(insucesso))
      expect(enviado).to have_been_made
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.registrar_insucesso_entrega("pedido 42", **insucesso) }.to raise_error(ArgumentError)
    end
  end

  describe "#cancelar_insucesso_entrega" do
    it "faz DELETE em /v2/nfe/{ref}/insucesso_entrega sem corpo", :aggregate_failures do
      stub_nfe(:delete, "nfe/pedido-42/insucesso_entrega")

      doc = nfe.cancelar_insucesso_entrega("pedido-42")

      expect(a_request(:delete, "#{homologacao}/v2/nfe/pedido-42/insucesso_entrega").with(body: nil))
        .to have_been_made
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end

    it "rejeita ref inválida sem requisição" do
      expect { nfe.cancelar_insucesso_entrega("pedido 42") }.to raise_error(ArgumentError)
    end
  end

  describe "#previa com validar: true" do
    it "levanta ErroDeValidacao sem fazer requisição quando faltam obrigatórios", :aggregate_failures do
      stub = stub_nfe(:post, "nfe/danfe", body: "%PDF-1.4")

      expect { nfe.previa(dados: {}, validar: true) }.to raise_error(FocusNfe::Esquemas::ErroDeValidacao)
      expect(stub).not_to have_been_requested
    end
  end
end
