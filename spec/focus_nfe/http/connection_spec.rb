# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Connection do
  subject(:connection) { described_class.new(config) }

  let(:config) { FocusNfe::Configuration.new(token: "tok", environment: environment, headers: extras) }
  let(:environment) { :homologacao }
  let(:extras) { {} }

  def homologacao = "https://homologacao.focusnfe.com.br"
  def producao = "https://api.focusnfe.com.br"

  def authorization(token)
    FocusNfe::HTTP::Authentication.header(token).fetch("Authorization")
  end

  def sent_header(url, headers)
    a_request(:get, url).with(headers: headers)
  end

  describe "montagem de URL" do
    it "monta base_url + /v2/ + caminho em homologação" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").to_return(status: 200, body: "")

      connection.get("nfe")

      expect(stub).to have_been_requested
    end

    context "when ambiente é produção" do
      let(:environment) { :producao }

      it "usa o host de produção" do
        stub = stub_request(:get, "#{producao}/v2/nfe").to_return(status: 200, body: "")

        connection.get("nfe")

        expect(stub).to have_been_requested
      end
    end

    it "normaliza barra inicial no caminho" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").to_return(status: 200, body: "")

      connection.get("/nfe")

      expect(stub).to have_been_requested
    end

    it "codifica params como query string" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").with(query: { ref: "pedido-42" })
      stub.to_return(status: 200, body: "")

      connection.get("nfe", params: { ref: "pedido-42" })

      expect(stub).to have_been_requested
    end
  end

  describe "verbos" do
    it "expõe get, post, put e delete", :aggregate_failures do
      %i[get post put delete].each { |verb| expect(connection).to respond_to(verb) }
    end

    it "serializa corpo Hash para JSON no POST" do
      stub = stub_request(:post, "#{homologacao}/v2/nfe").with(body: '{"ref":"x"}').to_return(status: 200, body: "")

      connection.post("nfe", body: { ref: "x" })

      expect(stub).to have_been_requested
    end

    it "não envia corpo quando body: é nil" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe").with { |req| req.body.nil? || req.body.empty? }
      stub.to_return(status: 200, body: "")

      connection.get("nfe")

      expect(stub).to have_been_requested
    end

    it "envia corpo no DELETE (cancelamento com justificativa)" do
      stub = stub_request(:delete, "#{homologacao}/v2/nfe/42").with(body: '{"justificativa":"erro"}')
      stub.to_return(status: 200, body: "")

      connection.delete("nfe/42", body: { justificativa: "erro" })

      expect(stub).to have_been_requested
    end
  end

  describe "cabeçalhos padrão" do
    let(:url) { "#{homologacao}/v2/nfe" }

    before { stub_request(:get, url).to_return(status: 200, body: "") }

    it "envia Content-Type e Accept JSON" do
      connection.get("nfe")

      headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(sent_header(url, headers)).to have_been_made
    end

    it "envia User-Agent baseado em FocusNfe::VERSION" do
      connection.get("nfe")

      expect(sent_header(url, "User-Agent" => "focus_nfe/#{FocusNfe::VERSION}")).to have_been_made
    end

    it "envia o Authorization Basic do token" do
      connection.get("nfe")

      expect(sent_header(url, "Authorization" => authorization("tok"))).to have_been_made
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
        connection.get("nfe")

        expect(sent_header(url, "X-Empresa" => "loja-1")).to have_been_made
      end
    end

    context "with extra tentando trocar o Authorization" do
      let(:extras) { { "Authorization" => "Basic invasor" } }

      it "mantém o Authorization calculado" do
        connection.get("nfe")

        expect(sent_header(url, "Authorization" => authorization("tok"))).to have_been_made
      end
    end

    it "permite a chamada sobrescrever o Content-Type (ex.: XML)" do
      connection.post("nfe", body: "<x/>", headers: { "Content-Type" => "application/xml" })

      expect(a_request(:post, url).with(headers: { "Content-Type" => "application/xml" })).to have_been_made
    end

    it "ignora um Authorization per-call, mantendo o calculado" do
      connection.get("nfe", headers: { "Authorization" => "Basic invasor" })

      expect(sent_header(url, "Authorization" => authorization("tok"))).to have_been_made
    end
  end

  describe "respostas" do
    let(:url) { "#{homologacao}/v2/nfe" }
    let(:json) { { "Content-Type" => "application/json" } }

    it "devolve a Response em 2xx", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: '{"ok":true}', headers: json)

      response = connection.get("nfe")

      expect(response).to be_a(FocusNfe::HTTP::Response)
      expect(response.body).to eq("ok" => true)
    end

    {
      400 => FocusNfe::Errors::BadRequest,
      401 => FocusNfe::Errors::Unauthorized,
      403 => FocusNfe::Errors::Forbidden,
      404 => FocusNfe::Errors::NotFound,
      409 => FocusNfe::Errors::Conflict,
      422 => FocusNfe::Errors::ValidationError,
      429 => FocusNfe::Errors::RateLimited,
      500 => FocusNfe::Errors::ServerError,
      418 => FocusNfe::Errors::UnexpectedResponse
    }.each do |status, klass|
      it "levanta #{klass} em status #{status}" do
        stub_request(:get, url).to_return(status: status, body: "")

        expect { connection.get("nfe") }.to raise_error(klass)
      end
    end

    it "preenche a exceção com status e corpo da resposta", :aggregate_failures do
      stub_request(:get, url).to_return(status: 422, body: '{"erro":"ref"}', headers: json)

      expect { connection.get("nfe") }.to raise_error do |error|
        expect(error).to have_attributes(status: 422, body: { "erro" => "ref" })
      end
    end
  end
end
