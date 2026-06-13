# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas do
  describe ".disponiveis" do
    it "lista os nomes dos documentos com schema empacotado", :aggregate_failures do
      disponiveis = described_class.disponiveis

      expect(disponiveis).to be_an(Array)
      expect(disponiveis).to all(be_a(String))
      expect(disponiveis).to include("nfe")
    end

    it "devolve os nomes ordenados e sem duplicatas", :aggregate_failures do
      disponiveis = described_class.disponiveis

      expect(disponiveis).to eq(disponiveis.uniq)
      expect(disponiveis).to eq(disponiveis.sort)
    end
  end

  describe ".descrever" do
    it "devolve a descrição estruturada de cada campo do documento", :aggregate_failures do
      campos = described_class.descrever("nfe")

      expect(campos).to be_an(Array)
      expect(campos).not_to be_empty
      expect(campos.first).to include(:nome, :tipo, :obrigatorio)
    end

    it "devolve nil quando não há schema para o documento" do
      expect(described_class.descrever("documento_inexistente")).to be_nil
    end

    it "devolve nil para nomes inválidos (traversal)" do
      expect(described_class.descrever("../../foo")).to be_nil
    end

    it "expõe os campos sem exigir token nem conexão" do
      expect { described_class.descrever("nfe") }.not_to raise_error
    end
  end
end
