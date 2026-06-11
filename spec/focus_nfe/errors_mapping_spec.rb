# frozen_string_literal: true

RSpec.describe FocusNfe::Errors do
  describe ".class_for" do
    {
      400 => FocusNfe::Errors::BadRequest,
      401 => FocusNfe::Errors::Unauthorized,
      403 => FocusNfe::Errors::Forbidden,
      404 => FocusNfe::Errors::NotFound,
      409 => FocusNfe::Errors::Conflict,
      422 => FocusNfe::Errors::ValidationError,
      429 => FocusNfe::Errors::RateLimited
    }.each do |status, klass|
      it "mapeia #{status} para #{klass}" do
        expect(described_class.class_for(status)).to eq(klass)
      end
    end

    it "mapeia qualquer 5xx para ServerError", :aggregate_failures do
      expect(described_class.class_for(500)).to eq(described_class::ServerError)
      expect(described_class.class_for(503)).to eq(described_class::ServerError)
      expect(described_class.class_for(599)).to eq(described_class::ServerError)
    end

    it "mapeia status não-2xx não previstos para UnexpectedResponse", :aggregate_failures do
      expect(described_class.class_for(418)).to eq(described_class::UnexpectedResponse)
      expect(described_class.class_for(451)).to eq(described_class::UnexpectedResponse)
      expect(described_class.class_for(300)).to eq(described_class::UnexpectedResponse)
    end
  end

  describe ".from_response" do
    def response(status:, body: nil)
      FocusNfe::HTTP::Response.new(
        status: status,
        headers: { "Content-Type" => "application/json" },
        body: body
      )
    end

    it "instancia a classe correta conforme o status" do
      error = described_class.from_response(response(status: 422))

      expect(error).to be_a(described_class::ValidationError)
    end

    it "preenche status, corpo e resposta a partir da Response", :aggregate_failures do
      original = response(status: 422, body: '{"mensagem":"ref inválida"}')
      error = described_class.from_response(original)

      expect(error.status).to eq(422)
      expect(error.body).to eq("mensagem" => "ref inválida")
      expect(error.response).to be(original)
    end

    it "usa UnexpectedResponse para status não mapeado" do
      error = described_class.from_response(response(status: 418))

      expect(error).to be_a(described_class::UnexpectedResponse)
    end

    it "produz uma exceção levantável que carrega o status na mensagem" do
      error = described_class.from_response(response(status: 500))

      expect { raise error }.to raise_error(described_class::ServerError, /500/)
    end
  end
end
