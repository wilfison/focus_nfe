# frozen_string_literal: true

RSpec.describe FocusNfe::Modelos::Inutilizacao do
  def response(body:, status: 200)
    FocusNfe::HTTP::Response.new(
      status: status,
      headers: { "Content-Type" => "application/json" },
      body: JSON.generate(body)
    )
  end

  describe ".from_response" do
    it "mapeia status, status_sefaz e mensagem_sefaz", :aggregate_failures do
      corpo = { "status" => "autorizado", "status_sefaz" => "102", "mensagem_sefaz" => "ok" }
      inut = described_class.from_response(response(body: corpo))

      expect(inut).to have_attributes(status: "autorizado", status_sefaz: "102", mensagem_sefaz: "ok")
    end

    it "mapeia serie, numero_inicial e numero_final", :aggregate_failures do
      corpo = { "serie" => "1", "numero_inicial" => "10", "numero_final" => "20" }
      inut = described_class.from_response(response(body: corpo))

      expect(inut).to have_attributes(serie: "1", numero_inicial: "10", numero_final: "20")
    end

    it "expõe protocolo a partir de protocolo_sefaz" do
      inut = described_class.from_response(response(body: { "protocolo_sefaz" => "135200" }))

      expect(inut.protocolo).to eq("135200")
    end

    it "guarda a resposta original para inspeção" do
      resp = response(body: { "status" => "autorizado" })

      expect(described_class.from_response(resp).response).to be(resp)
    end

    it "usa dados vazios quando o corpo não é um Hash", :aggregate_failures do
      inut = described_class.from_response(response(body: ["x"]))

      expect(inut.dados).to eq({})
      expect(inut.status).to be_nil
    end
  end

  describe ".from_item" do
    it "constrói a partir de um Hash cru, sem resposta", :aggregate_failures do
      inut = described_class.from_item("status" => "autorizado", "protocolo_sefaz" => "1")

      expect(inut.response).to be_nil
      expect(inut).to have_attributes(status: "autorizado", protocolo: "1")
    end

    it "usa dados vazios quando o item não é um Hash" do
      expect(described_class.from_item(nil).dados).to eq({})
    end
  end

  describe "#autorizado?" do
    def inut(status)
      described_class.from_item("status" => status)
    end

    it "é verdadeiro só para 'autorizado'", :aggregate_failures do
      expect(inut("autorizado")).to be_autorizado
      expect(inut("erro_autorizacao")).not_to be_autorizado
    end
  end

  describe "acesso bruto" do
    subject(:inut) do
      described_class.from_item("status" => "autorizado", "cnpj" => "123", "modelo" => "55", "caminho_xml" => "/x.xml")
    end

    it "expõe o Hash cru via #dados" do
      expect(inut.dados).to include("cnpj" => "123", "modelo" => "55", "caminho_xml" => "/x.xml")
    end

    it "delega #[] ao Hash para campos não mapeados", :aggregate_failures do
      expect(inut["cnpj"]).to eq("123")
      expect(inut["caminho_xml"]).to eq("/x.xml")
    end
  end

  describe "imutabilidade" do
    it "congela a instância" do
      expect(described_class.from_item("status" => "autorizado")).to be_frozen
    end
  end
end
