# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Concerns::Emitivel do
  let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :homologacao) }
  let(:nfe) { FocusNfe::Recursos::Nfe.new(client.connection) }
  let(:nfce) { FocusNfe::Recursos::Nfce.new(client.connection) }
  let(:cte) { FocusNfe::Recursos::Cte.new(client.connection) }
  let(:cte_os) { FocusNfe::Recursos::CteOs.new(client.connection) }
  let(:mdfe) { FocusNfe::Recursos::Mdfe.new(client.connection) }

  def json = { "Content-Type" => "application/json" }
  def processando = '{"status":"processando_autorizacao"}'
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

    context "quando o documento tem modal condicional (CTe)" do
      def stub_esquema_base_vazio
        vazio = FocusNfe::Esquemas::Esquema.new([])
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).and_call_original
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).with("cte").and_return(vazio)
      end

      it "valida o sub-esquema do modal e bloqueia a emissão" do
        stub_esquema_base_vazio

        expect do
          cte.emitir(ref: "cte-1", dados: { "modal" => "01", "modal_rodoviario" => { "rntrc" => "1" } }, validar: true)
        end.to raise_error(FocusNfe::Esquemas::ErroDeValidacao, /modal_rodoviario/)
      end

      it "emite quando base e modal são válidos" do
        stub_esquema_base_vazio
        stub_emissao("cte?ref=cte-1")

        cte.emitir(ref: "cte-1", dados: { "modal" => "01", "modal_rodoviario" => { "rntrc" => "12345678" } },
                   validar: true)

        expect(a_request(:post, "#{homologacao}/v2/cte?ref=cte-1")).to have_been_made
      end
    end

    context "quando o CTe OS tem modal condicional" do
      def stub_cte_os_base_vazio
        vazio = FocusNfe::Esquemas::Esquema.new([])
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).and_call_original
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).with("cte_os").and_return(vazio)
      end

      it "valida o sub-esquema do modal e bloqueia a emissão" do
        stub_cte_os_base_vazio

        expect do
          cte_os.emitir(ref: "cte-os-1", dados: { "modal" => "01", "modal_rodoviario" => { "placa" => "ABC1234" } },
                        validar: true)
        end.to raise_error(FocusNfe::Esquemas::ErroDeValidacao, /modal_rodoviario\.placa/)
      end

      it "emite quando base e modal são válidos" do
        stub_cte_os_base_vazio
        stub_emissao("cte_os?ref=cte-os-1")

        cte_os.emitir(ref: "cte-os-1", dados: { "modal" => "01", "modal_rodoviario" => { "placa" => "AB12" } },
                      validar: true)

        expect(a_request(:post, "#{homologacao}/v2/cte_os?ref=cte-os-1")).to have_been_made
      end

      it "não valida modal quando o campo modal não é 01" do
        stub_cte_os_base_vazio
        stub_emissao("cte_os?ref=cte-os-1")

        cte_os.emitir(ref: "cte-os-1", dados: { "modal" => "02", "modal_rodoviario" => { "placa" => "ABC1234" } },
                      validar: true)

        expect(a_request(:post, "#{homologacao}/v2/cte_os?ref=cte-os-1")).to have_been_made
      end
    end

    context "quando a MDFe deduz o modal pela chave presente" do
      def stub_mdfe_base_vazia
        vazio = FocusNfe::Esquemas::Esquema.new([])
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).and_call_original
        allow(FocusNfe::Esquemas::Esquema).to receive(:carregar).with("mdfe").and_return(vazio)
      end

      it "valida o sub-esquema do modal presente e bloqueia a emissão" do
        stub_mdfe_base_vazia

        expect do
          mdfe.emitir(ref: "mdfe-1", dados: { "modal_rodoviario" => {} }, validar: true)
        end.to raise_error(FocusNfe::Esquemas::ErroDeValidacao, /modal_rodoviario/)
      end

      it "emite quando nenhuma chave de modal está presente" do
        stub_mdfe_base_vazia
        stub_emissao("mdfe?ref=mdfe-1")

        mdfe.emitir(ref: "mdfe-1", dados: { "cnpj_emitente" => "12345678000123" }, validar: true)

        expect(a_request(:post, "#{homologacao}/v2/mdfe?ref=mdfe-1")).to have_been_made
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
