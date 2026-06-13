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

    it "devolve nil para nomes inválidos (traversal)", :aggregate_failures do
      expect(described_class.carregar("../../../../etc/hostname")).to be_nil
      expect(described_class.carregar("nfe/../nfe")).to be_nil
      expect(described_class.carregar("../secret")).to be_nil
    end

    it "não consulta o filesystem para nomes inválidos" do
      allow(File).to receive(:exist?).and_call_original

      described_class.carregar("../../../../etc/passwd")

      expect(File).not_to have_received(:exist?)
    end

    it "não memoiza nomes inválidos (cache permanece limitado)" do
      described_class.carregar("../etc/hostname")

      expect(described_class.send(:cache)).not_to have_key("../etc/hostname")
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

  describe "#descrever" do
    let(:definicoes) do
      [
        { "name" => "serie", "type" => "String[1-3]", "required" => true },
        { "name" => "numero", "type" => "Integer[1-9]", "required" => true }
      ]
    end

    it "descreve cada campo como um Hash", :aggregate_failures do
      descricao = described_class.new(definicoes).descrever

      expect(descricao).to eq(definicoes.map { |d| FocusNfe::Esquemas::Campo.new(d).to_h })
      expect(descricao.map { |c| c[:nome] }).to eq(%w[serie numero])
    end
  end
end
