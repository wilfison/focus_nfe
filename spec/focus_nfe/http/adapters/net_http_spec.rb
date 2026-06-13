# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Adapters::NetHttp do
  subject(:adapter) { described_class.new(timeout: 30, open_timeout: 10) }

  let(:url) { "https://api.exemplo.test/recurso" }
  let(:json) { { "Content-Type" => "application/json" } }

  def capture_http
    http = nil
    allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
      http = original.call(*args)
    end
    yield
    http
  end

  it "é um Adapter" do
    expect(adapter).to be_a(FocusNfe::HTTP::Adapter)
  end

  describe "#call" do
    it "devolve uma Response com status e corpo parseado", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: '{"ok":true}', headers: json)

      response = adapter.call(:get, url)

      expect(response).to be_a(FocusNfe::HTTP::Response)
      expect(response).to have_attributes(status: 200, body: { "ok" => true })
    end

    %i[get post put delete].each do |verb|
      it "suporta o verbo #{verb}" do
        stub = stub_request(verb, url).to_return(status: 200, body: "")

        adapter.call(verb, url)

        expect(stub).to have_been_requested
      end
    end

    it "envia o corpo no POST" do
      stub = stub_request(:post, url).with(body: '{"a":1}').to_return(status: 201, body: "")

      adapter.call(:post, url, headers: json, body: '{"a":1}')

      expect(stub).to have_been_requested
    end

    it "envia o corpo no DELETE (cancelamento com justificativa)" do
      stub = stub_request(:delete, url).with(body: '{"justificativa":"erro"}').to_return(status: 200, body: "")

      adapter.call(:delete, url, body: '{"justificativa":"erro"}')

      expect(stub).to have_been_requested
    end

    it "respeita um Content-Type não-JSON no corpo da requisição" do
      headers = { "Content-Type" => "application/xml" }
      stub = stub_request(:post, url).with(body: "<x/>", headers: headers).to_return(status: 200, body: "")

      adapter.call(:post, url, headers: headers, body: "<x/>")

      expect(stub).to have_been_requested
    end

    it "repassa corpo de resposta não-JSON cru, sem estourar" do
      headers = { "Content-Type" => "application/xml" }
      stub_request(:get, url).to_return(status: 200, body: "<nfe>...</nfe>", headers: headers)

      expect(adapter.call(:get, url).body).to eq("<nfe>...</nfe>")
    end

    it "aplica timeout e open_timeout ao cliente Net::HTTP", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: "")

      http = capture_http { described_class.new(timeout: 7, open_timeout: 3).call(:get, url) }

      expect(http).to have_attributes(read_timeout: 7, open_timeout: 3)
    end

    it "não força timeouts quando não configurados, mantendo os defaults do Net::HTTP", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: "")
      padrao = Net::HTTP.new("x")

      http = capture_http { described_class.new.call(:get, url) }

      expect(http.read_timeout).to eq(padrao.read_timeout)
      expect(http.open_timeout).to eq(padrao.open_timeout)
    end

    it "usa TLS quando a URL é https" do
      stub_request(:get, url).to_return(status: 200, body: "")

      http = capture_http { adapter.call(:get, url) }

      expect(http.use_ssl?).to be(true)
    end
  end

  describe "redirecionamento 302" do
    let(:origin) { "https://api.exemplo.test/nfe/123.pdf" }
    let(:target) { "https://arquivos.exemplo.test/assinado/123.pdf" }

    def stub_redirect
      stub_request(:get, origin).to_return(status: 302, headers: { "Location" => target })
      stub_request(:get, target).to_return(status: 200, body: "PDF")
    end

    it "segue o Location com um novo GET e devolve a resposta final" do
      stub_redirect

      response = adapter.call(:get, origin, headers: { "Authorization" => "Basic abc" })

      expect(response.status).to eq(200)
    end

    it "não reenvia o cabeçalho Authorization ao seguir o 302" do
      stub_redirect

      adapter.call(:get, origin, headers: { "Authorization" => "Basic abc" })

      expect(a_request(:get, target).with { |req| req.headers["Authorization"].nil? }).to have_been_made
    end

    it "recusa redirecionamento para destino não-https", :aggregate_failures do
      destino_http = "http://arquivos.exemplo.test/assinado/123.pdf"
      stub_request(:get, origin).to_return(status: 302, headers: { "Location" => destino_http })
      segundo = stub_request(:get, destino_http)

      expect { adapter.call(:get, origin) }.to raise_error(FocusNfe::Errors::ConnectionError, /não-https/)
      expect(segundo).not_to have_been_requested
    end

    it "não segue outros 3xx além de 302 (devolve a resposta crua)" do
      stub_request(:get, url).to_return(status: 301, headers: { "Location" => "https://outro.test/x" })

      expect(adapter.call(:get, url).status).to eq(301)
    end

    it "levanta ConnectionError ao exceder o teto de 5 redirecionamentos" do
      stub_request(:get, url).to_return(status: 302, headers: { "Location" => url })

      expect { adapter.call(:get, url) }.to raise_error(FocusNfe::Errors::ConnectionError)
    end
  end

  describe "falhas de transporte" do
    it "relança timeout como ConnectionError" do
      stub_request(:get, url).to_timeout

      expect { adapter.call(:get, url) }.to raise_error(FocusNfe::Errors::ConnectionError)
    end

    it "relança conexão recusada como ConnectionError" do
      stub_request(:get, url).to_raise(Errno::ECONNREFUSED)

      expect { adapter.call(:get, url) }.to raise_error(FocusNfe::Errors::ConnectionError)
    end
  end
end
