# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Concerns::Emitivel do
  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :homologacao) }
  let(:nfe) { FocusNfe::Recursos::Nfe.new(client.connection) }
  let(:nfce) { FocusNfe::Recursos::Nfce.new(client.connection) }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:processando) { '{"status":"processando_autorizacao"}' }

  def homologacao = "https://homologacao.focusnfe.com.br"

  def stub_emissao(path, status: 202)
    stub_request(:post, "#{homologacao}/v2/#{path}").to_return(status: status, body: processando, headers: json)
  end

  describe "#emitir com validar: true" do
    context "quando o documento tem schema empacotado" do
      it "levanta ErroDeValidacao sem fazer requisição quando faltam obrigatórios", :aggregate_failures do
        stub = stub_emissao("nfe?ref=pedido-1")

        expect { nfe.emitir(ref: "pedido-1", dados: {}, validar: true) }
          .to raise_error(FocusNfe::Esquemas::ErroDeValidacao)
        expect(stub).not_to have_been_requested
      end

      it "emite normalmente quando os dados são válidos" do
        esquema = FocusNfe::Esquemas::Esquema.new([{ "name" => "natureza_operacao", "type" => "String[1-60]" }])
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).with("nfe").and_return(esquema)
        stub_emissao("nfe?ref=pedido-1")

        nfe.emitir(ref: "pedido-1", dados: { "natureza_operacao" => "Venda" }, validar: true)

        expect(a_request(:post, "#{homologacao}/v2/nfe?ref=pedido-1")).to have_been_made
      end

      it "não vaza o parâmetro validar para a query string" do
        esquema = FocusNfe::Esquemas::Esquema.new([])
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).with("nfe").and_return(esquema)
        stub_emissao("nfe?ref=pedido-1")

        nfe.emitir(ref: "pedido-1", dados: {}, validar: true)

        expect(a_request(:post, "#{homologacao}/v2/nfe").with(query: { "ref" => "pedido-1" })).to have_been_made
      end
    end

    context "quando o documento não tem schema (pula silenciosamente)" do
      it "emite sem validar" do
        stub_emissao("nfce?ref=venda-1")

        nfce.emitir(ref: "venda-1", dados: {}, validar: true)

        expect(a_request(:post, "#{homologacao}/v2/nfce?ref=venda-1")).to have_been_made
      end
    end
  end

  describe "#emitir sem validar (padrão)" do
    it "não valida mesmo com dados vazios" do
      stub_emissao("nfe?ref=pedido-1")

      nfe.emitir(ref: "pedido-1", dados: {})

      expect(a_request(:post, "#{homologacao}/v2/nfe?ref=pedido-1")).to have_been_made
    end
  end
end
