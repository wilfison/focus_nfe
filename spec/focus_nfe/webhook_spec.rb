# frozen_string_literal: true

RSpec.describe FocusNfe::Webhook do
  describe ".parse" do
    it "parseia o corpo cru (String) em um Documento", :aggregate_failures do
      doc = described_class.parse('{"status":"autorizado","ref":"pedido-1"}')

      expect(doc).to be_a(FocusNfe::Modelos::Documento)
      expect(doc).to be_autorizado
      expect(doc.ref).to eq("pedido-1")
    end

    it "aceita um Hash já parseado" do
      doc = described_class.parse({ "status" => "cancelado", "ref" => "pedido-2" })

      expect(doc).to be_cancelado
    end

    it "injeta a ref informada quando o corpo não a traz" do
      doc = described_class.parse('{"status":"autorizado"}', ref: "pedido-3")

      expect(doc.ref).to eq("pedido-3")
    end

    it "não guarda resposta HTTP" do
      expect(described_class.parse('{"status":"autorizado"}').response).to be_nil
    end

    it "levanta WebhookError quando o corpo não é JSON válido" do
      expect { described_class.parse("nao é json") }
        .to raise_error(FocusNfe::Errors::WebhookError, /não é JSON válido/)
    end
  end

  describe ".autenticado?" do
    let(:headers) { { "X-Focus-Authorization" => "s3cr3t" } }

    def autenticado?(headers:, authorization: "s3cr3t", authorization_header: "X-Focus-Authorization")
      described_class.autenticado?(headers: headers, authorization: authorization,
                                   authorization_header: authorization_header)
    end

    it "é verdadeiro quando o header recebido bate com o authorization" do
      expect(autenticado?(headers: headers)).to be(true)
    end

    it "é falso quando o valor do header diverge" do
      expect(autenticado?(headers: { "X-Focus-Authorization" => "errado" })).to be(false)
    end

    it "é falso quando o header está ausente" do
      expect(autenticado?(headers: {})).to be(false)
    end

    it "faz o lookup do header de forma case-insensitive" do
      expect(autenticado?(headers: { "x-focus-authorization" => "s3cr3t" })).to be(true)
    end

    it "encontra o header via #[] em objetos sem #each (ex.: request.headers)" do
      rails_like = Object.new
      def rails_like.[](nome) = nome == "X-Focus-Authorization" ? "s3cr3t" : nil

      expect(autenticado?(headers: rails_like)).to be(true)
    end
  end
end
