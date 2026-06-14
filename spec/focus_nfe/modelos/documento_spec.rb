# frozen_string_literal: true

RSpec.describe FocusNfe::Modelos::Documento do
  def response(body:, status: 200)
    FocusNfe::HTTP::Response.new(
      status: status,
      headers: { "Content-Type" => "application/json" },
      body: JSON.generate(body)
    )
  end

  describe ".from_response" do
    it "mapeia status, status_sefaz e mensagem_sefaz", :aggregate_failures do
      corpo = { "status" => "autorizado", "status_sefaz" => "100", "mensagem_sefaz" => "ok" }
      doc = described_class.from_response(response(body: corpo))

      expect(doc).to have_attributes(status: "autorizado", status_sefaz: "100", mensagem_sefaz: "ok")
    end

    it "mapeia chave, numero e serie", :aggregate_failures do
      corpo = { "chave_nfe" => "3520", "numero" => "42", "serie" => "1" }
      doc = described_class.from_response(response(body: corpo))

      expect(doc).to have_attributes(chave_nfe: "3520", numero: "42", serie: "1")
    end

    it "mapeia os caminhos de XML e DANFe", :aggregate_failures do
      corpo = { "caminho_xml_nota_fiscal" => "/x.xml", "caminho_danfe" => "/x.pdf" }
      doc = described_class.from_response(response(body: corpo))

      expect(doc).to have_attributes(caminho_xml_nota_fiscal: "/x.xml", caminho_danfe: "/x.pdf")
    end

    it "mapeia os campos da carta de correção", :aggregate_failures do
      corpo = { "caminho_xml_carta_correcao" => "/cce.xml", "caminho_pdf_carta_correcao" => "/cce.pdf",
                "numero_carta_correcao" => "1" }
      doc = described_class.from_response(response(body: corpo))

      expect(doc).to have_attributes(caminho_xml_carta_correcao: "/cce.xml",
                                     caminho_pdf_carta_correcao: "/cce.pdf",
                                     numero_carta_correcao: "1")
    end

    it "injeta a ref conhecida pela chamada quando o corpo não a traz" do
      doc = described_class.from_response(response(body: { "status" => "processando_autorizacao" }), ref: "pedido-42")

      expect(doc.ref).to eq("pedido-42")
    end

    it "guarda a resposta original para inspeção" do
      resp = response(body: { "status" => "autorizado" })

      expect(described_class.from_response(resp).response).to be(resp)
    end

    it "usa dados vazios quando o corpo não é um Hash", :aggregate_failures do
      doc = described_class.from_response(response(body: ["x"]))

      expect(doc.dados).to eq({})
      expect(doc.status).to be_nil
    end
  end

  describe "predicados de status" do
    def doc(status)
      described_class.from_response(response(body: { "status" => status }))
    end

    it "autorizado? é verdadeiro só para 'autorizado'", :aggregate_failures do
      expect(doc("autorizado")).to be_autorizado
      expect(doc("cancelado")).not_to be_autorizado
    end

    it "cancelado? é verdadeiro só para 'cancelado'", :aggregate_failures do
      expect(doc("cancelado")).to be_cancelado
      expect(doc("autorizado")).not_to be_cancelado
    end

    it "processando? é verdadeiro para 'processando_autorizacao'", :aggregate_failures do
      expect(doc("processando_autorizacao")).to be_processando
      expect(doc("autorizado")).not_to be_processando
    end

    it "erro? é verdadeiro para status que começam com 'erro'", :aggregate_failures do
      expect(doc("erro_autorizacao")).to be_erro
      expect(doc("autorizado")).not_to be_erro
    end

    it "denegado? é verdadeiro só para 'denegado'", :aggregate_failures do
      expect(doc("denegado")).to be_denegado
      expect(doc("autorizado")).not_to be_denegado
    end
  end

  describe "acesso bruto" do
    subject(:doc) do
      described_class.from_response(response(body: { "status" => "autorizado", "extra" => "valor" }))
    end

    it "expõe o Hash cru via #dados" do
      expect(doc.dados).to include("status" => "autorizado", "extra" => "valor")
    end

    it "delega #[] ao Hash para campos não mapeados" do
      expect(doc["extra"]).to eq("valor")
    end
  end

  describe "imutabilidade" do
    it "congela a instância" do
      expect(described_class.from_response(response(body: { "status" => "autorizado" }))).to be_frozen
    end
  end
end
