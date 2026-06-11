# frozen_string_literal: true

RSpec.describe FocusNfe::Errors do
  describe "FocusNfe::Error (raiz da hierarquia)" do
    it "descende de StandardError" do
      expect(FocusNfe::Error.new).to be_a(StandardError)
    end

    it "substitui a antiga FocusNfe::Erro (português), que deixa de existir" do
      expect(FocusNfe.const_defined?(:Erro, false)).to be(false)
    end
  end

  describe FocusNfe::Errors::HttpError do
    it "descende de FocusNfe::Error" do
      expect(described_class.ancestors).to include(FocusNfe::Error)
    end

    it "expõe status, corpo e resposta informados na construção" do
      response = Object.new
      error = described_class.new("falhou", status: 422, body: { "msg" => "ref" }, response: response)

      expect(error).to have_attributes(message: "falhou", status: 422, body: { "msg" => "ref" }, response: response)
    end

    it "pode ser construído sem argumentos, com leitores nil", :aggregate_failures do
      error = described_class.new

      expect(error.status).to be_nil
      expect(error.body).to be_nil
      expect(error.response).to be_nil
    end
  end

  describe "subclasses tipadas de HttpError" do
    %i[
      BadRequest Unauthorized Forbidden NotFound Conflict
      ValidationError RateLimited ServerError UnexpectedResponse
    ].each do |name|
      it "#{name} descende de HttpError, Error e StandardError", :aggregate_failures do
        klass = described_class.const_get(name)

        expect(klass.ancestors).to include(FocusNfe::Errors::HttpError)
        expect(klass.ancestors).to include(FocusNfe::Error)
        expect(klass.ancestors).to include(StandardError)
      end
    end

    it "reúnem exatamente 9 classes distintas, sem aliasing" do
      todas = described_class.constants.map { |name| described_class.const_get(name) }
      subclasses = todas.select { |const| const.is_a?(Class) && const < described_class::HttpError }

      expect(subclasses.uniq.size).to eq(9)
    end
  end

  describe "erros não-HTTP (client-side e transporte)" do
    it "ConfigurationError descende de Error, mas não de HttpError", :aggregate_failures do
      ancestrais = FocusNfe::Errors::ConfigurationError.ancestors

      expect(ancestrais).to include(FocusNfe::Error)
      expect(ancestrais).not_to include(FocusNfe::Errors::HttpError)
    end

    it "ConnectionError descende de Error, mas não de HttpError", :aggregate_failures do
      ancestrais = FocusNfe::Errors::ConnectionError.ancestors

      expect(ancestrais).to include(FocusNfe::Error)
      expect(ancestrais).not_to include(FocusNfe::Errors::HttpError)
    end
  end
end
