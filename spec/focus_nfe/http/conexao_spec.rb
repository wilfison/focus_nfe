# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Conexao do
  subject(:conexao) { described_class.new(config) }

  let(:config) { FocusNfe::Configuracao.new(token: "tok", ambiente: ambiente, cabecalhos: extras) }
  let(:ambiente) { :homologacao }
  let(:extras) { {} }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def autorizacao(token)
    FocusNfe::HTTP::Autenticacao.cabecalho(token).fetch("Authorization")
  end

  def cabecalho_enviado(url, headers)
    a_request(:get, url).with(headers: headers)
  end

  describe "montagem de URL" do
    it "monta url_base + /v2/ + caminho em homologação" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").to_return(status: 200, body: "")

      conexao.get("nfe")

      expect(stub).to have_been_requested
    end

    context "when ambiente é produção" do
      let(:ambiente) { :producao }

      it "usa o host de produção" do
        stub = stub_request(:get, "#{producao}/v2/nfe").to_return(status: 200, body: "")

        conexao.get("nfe")

        expect(stub).to have_been_requested
      end
    end

    it "normaliza barra inicial no caminho" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").to_return(status: 200, body: "")

      conexao.get("/nfe")

      expect(stub).to have_been_requested
    end

    it "codifica parametros como query string" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").with(query: { ref: "pedido-42" })
      stub.to_return(status: 200, body: "")

      conexao.get("nfe", parametros: { ref: "pedido-42" })

      expect(stub).to have_been_requested
    end
  end

  describe "verbos" do
    it "expõe get, post, put e delete", :aggregate_failures do
      %i[get post put delete].each { |verbo| expect(conexao).to respond_to(verbo) }
    end

    it "serializa corpo Hash para JSON no POST" do
      stub = stub_request(:post, "#{homologacao}/v2/nfe").with(body: '{"ref":"x"}').to_return(status: 200, body: "")

      conexao.post("nfe", corpo: { ref: "x" })

      expect(stub).to have_been_requested
    end

    it "não envia corpo quando corpo: é nil" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").with { |req| req.body.nil? || req.body.empty? }
      stub.to_return(status: 200, body: "")

      conexao.get("nfe")

      expect(stub).to have_been_requested
    end

    it "envia corpo no DELETE (cancelamento com justificativa)" do
      stub = stub_request(:delete, "#{homologacao}/v2/nfe/42").with(body: '{"justificativa":"erro"}')
      stub.to_return(status: 200, body: "")

      conexao.delete("nfe/42", corpo: { justificativa: "erro" })

      expect(stub).to have_been_requested
    end
  end

  describe "cabeçalhos padrão" do
    let(:url) { "#{homologacao}/v2/nfe" }

    before { stub_request(:get, url).to_return(status: 200, body: "") }

    it "envia Content-Type e Accept JSON" do
      conexao.get("nfe")

      headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(cabecalho_enviado(url, headers)).to have_been_made
    end

    it "envia User-Agent baseado em FocusNfe::VERSION" do
      conexao.get("nfe")

      expect(cabecalho_enviado(url, "User-Agent" => "focus_nfe/#{FocusNfe::VERSION}")).to have_been_made
    end

    it "envia o Authorization Basic do token" do
      conexao.get("nfe")

      expect(cabecalho_enviado(url, "Authorization" => autorizacao("tok"))).to have_been_made
    end
  end

  describe "precedência de cabeçalhos" do
    let(:url) { "#{homologacao}/v2/nfe" }

    before do
      stub_request(:get, url).to_return(status: 200, body: "")
      stub_request(:post, url).to_return(status: 200, body: "")
    end

    context "with extra customizado na config" do
      let(:extras) { { "X-Empresa" => "loja-1" } }

      it "adiciona o header extra à requisição" do
        conexao.get("nfe")

        expect(cabecalho_enviado(url, "X-Empresa" => "loja-1")).to have_been_made
      end
    end

    context "with extra tentando trocar o Authorization" do
      let(:extras) { { "Authorization" => "Basic invasor" } }

      it "mantém o Authorization calculado" do
        conexao.get("nfe")

        expect(cabecalho_enviado(url, "Authorization" => autorizacao("tok"))).to have_been_made
      end
    end

    it "permite a chamada sobrescrever o Content-Type (ex.: XML)" do
      conexao.post("nfe", corpo: "<x/>", cabecalhos: { "Content-Type" => "application/xml" })

      expect(a_request(:post, url).with(headers: { "Content-Type" => "application/xml" })).to have_been_made
    end

    it "ignora um Authorization per-call, mantendo o calculado" do
      conexao.get("nfe", cabecalhos: { "Authorization" => "Basic invasor" })

      expect(cabecalho_enviado(url, "Authorization" => autorizacao("tok"))).to have_been_made
    end
  end

  describe "respostas" do
    let(:url) { "#{homologacao}/v2/nfe" }
    let(:json) { { "Content-Type" => "application/json" } }

    it "devolve a Resposta em 2xx", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: '{"ok":true}', headers: json)

      resposta = conexao.get("nfe")

      expect(resposta).to be_a(FocusNfe::HTTP::Resposta)
      expect(resposta.corpo).to eq("ok" => true)
    end

    {
      400 => FocusNfe::Erros::RequisicaoInvalida,
      401 => FocusNfe::Erros::NaoAutorizado,
      403 => FocusNfe::Erros::Proibido,
      404 => FocusNfe::Erros::NaoEncontrado,
      409 => FocusNfe::Erros::Conflito,
      422 => FocusNfe::Erros::ErroDeValidacao,
      429 => FocusNfe::Erros::LimiteDeRequisicoes,
      500 => FocusNfe::Erros::ErroDoServidor,
      418 => FocusNfe::Erros::RespostaInesperada
    }.each do |status, classe|
      it "levanta #{classe} em status #{status}" do
        stub_request(:get, url).to_return(status: status, body: "")

        expect { conexao.get("nfe") }.to raise_error(classe)
      end
    end

    it "preenche a exceção com status e corpo da resposta", :aggregate_failures do
      stub_request(:get, url).to_return(status: 422, body: '{"erro":"ref"}', headers: json)

      expect { conexao.get("nfe") }.to raise_error do |erro|
        expect(erro).to have_attributes(status: 422, corpo: { "erro" => "ref" })
      end
    end
  end
end
