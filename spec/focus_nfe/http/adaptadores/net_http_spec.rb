# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Adaptadores::NetHttp do
  subject(:adaptador) { described_class.new(timeout: 30, open_timeout: 10) }

  let(:url) { "https://api.exemplo.test/recurso" }
  let(:json) { { "Content-Type" => "application/json" } }

  def capturar_cliente
    cliente = nil
    allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
      cliente = original.call(*args)
    end
    yield
    cliente
  end

  it "é um Adaptador" do
    expect(adaptador).to be_a(FocusNfe::HTTP::Adaptador)
  end

  describe "#executar" do
    it "devolve uma Resposta com status e corpo parseado", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: '{"ok":true}', headers: json)

      resposta = adaptador.executar(:get, url)

      expect(resposta).to be_a(FocusNfe::HTTP::Resposta)
      expect(resposta).to have_attributes(status: 200, corpo: { "ok" => true })
    end

    %i[get post put delete].each do |verbo|
      it "suporta o verbo #{verbo}" do
        stub = stub_request(verbo, url).to_return(status: 200, body: "")

        adaptador.executar(verbo, url)

        expect(stub).to have_been_requested
      end
    end

    it "envia o corpo no POST" do
      stub = stub_request(:post, url).with(body: '{"a":1}').to_return(status: 201, body: "")

      adaptador.executar(:post, url, cabecalhos: json, corpo: '{"a":1}')

      expect(stub).to have_been_requested
    end

    it "envia o corpo no DELETE (cancelamento com justificativa)" do
      stub = stub_request(:delete, url).with(body: '{"justificativa":"erro"}').to_return(status: 200, body: "")

      adaptador.executar(:delete, url, corpo: '{"justificativa":"erro"}')

      expect(stub).to have_been_requested
    end

    it "respeita um Content-Type não-JSON no corpo da requisição" do
      headers = { "Content-Type" => "application/xml" }
      stub = stub_request(:post, url).with(body: "<x/>", headers: headers).to_return(status: 200, body: "")

      adaptador.executar(:post, url, cabecalhos: headers, corpo: "<x/>")

      expect(stub).to have_been_requested
    end

    it "repassa corpo de resposta não-JSON cru, sem estourar" do
      headers = { "Content-Type" => "application/xml" }
      stub_request(:get, url).to_return(status: 200, body: "<nfe>...</nfe>", headers: headers)

      expect(adaptador.executar(:get, url).corpo).to eq("<nfe>...</nfe>")
    end

    it "aplica timeout e open_timeout ao cliente Net::HTTP", :aggregate_failures do
      stub_request(:get, url).to_return(status: 200, body: "")

      cliente = capturar_cliente { described_class.new(timeout: 7, open_timeout: 3).executar(:get, url) }

      expect(cliente).to have_attributes(read_timeout: 7, open_timeout: 3)
    end

    it "usa TLS quando a URL é https" do
      stub_request(:get, url).to_return(status: 200, body: "")

      cliente = capturar_cliente { adaptador.executar(:get, url) }

      expect(cliente.use_ssl?).to be(true)
    end
  end

  describe "redirecionamento 302" do
    let(:origem) { "https://api.exemplo.test/nfe/123.pdf" }
    let(:destino) { "https://arquivos.exemplo.test/assinado/123.pdf" }

    def stubar_redirecionamento
      stub_request(:get, origem).to_return(status: 302, headers: { "Location" => destino })
      stub_request(:get, destino).to_return(status: 200, body: "PDF")
    end

    it "segue o Location com um novo GET e devolve a resposta final" do
      stubar_redirecionamento

      resposta = adaptador.executar(:get, origem, cabecalhos: { "Authorization" => "Basic abc" })

      expect(resposta.status).to eq(200)
    end

    it "não reenvia o cabeçalho Authorization ao seguir o 302" do
      stubar_redirecionamento

      adaptador.executar(:get, origem, cabecalhos: { "Authorization" => "Basic abc" })

      expect(a_request(:get, destino).with { |req| req.headers["Authorization"].nil? }).to have_been_made
    end

    it "não segue outros 3xx além de 302 (devolve a resposta crua)" do
      stub_request(:get, url).to_return(status: 301, headers: { "Location" => "https://outro.test/x" })

      expect(adaptador.executar(:get, url).status).to eq(301)
    end

    it "levanta ErroDeConexao ao exceder o teto de 5 redirecionamentos" do
      stub_request(:get, url).to_return(status: 302, headers: { "Location" => url })

      expect { adaptador.executar(:get, url) }.to raise_error(FocusNfe::Erros::ErroDeConexao)
    end
  end

  describe "falhas de transporte" do
    it "relança timeout como ErroDeConexao" do
      stub_request(:get, url).to_timeout

      expect { adaptador.executar(:get, url) }.to raise_error(FocusNfe::Erros::ErroDeConexao)
    end

    it "relança conexão recusada como ErroDeConexao" do
      stub_request(:get, url).to_raise(Errno::ECONNREFUSED)

      expect { adaptador.executar(:get, url) }.to raise_error(FocusNfe::Erros::ErroDeConexao)
    end
  end
end
