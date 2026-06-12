# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas::Esquema do
  describe ".carregar" do
    it "carrega o schema empacotado de um documento conhecido", :aggregate_failures do
      esquema = described_class.carregar("nfe")

      expect(esquema).to be_a(described_class)
      expect(esquema.campos).to all(be_a(FocusNfe::Esquemas::Campo))
      expect(esquema.campos).not_to be_empty
    end

    it "devolve nil quando não há schema para o documento" do
      expect(described_class.carregar("nfce")).to be_nil
    end

    it "memoiza o schema carregado" do
      expect(described_class.carregar("nfe")).to equal(described_class.carregar("nfe"))
    end
  end

  describe "#campos" do
    let(:definicoes) do
      [
        { "name" => "serie", "type" => "String[1-3]", "required" => true },
        { "name" => "numero", "type" => "Integer[1-9]", "required" => true }
      ]
    end

    it "constrói Campos a partir das definições in-memory", :aggregate_failures do
      esquema = described_class.new(definicoes)

      expect(esquema.campos.map(&:nome)).to eq(%w[serie numero])
      expect(esquema.campos.first).to be_obrigatorio
    end
  end
end
