# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas::Decimal do
  describe ".parsear" do
    it "devolve nil para tipo que não é decimal", :aggregate_failures do
      expect(described_class.parsear(nil)).to be_nil
      expect(described_class.parsear("String[1-60]")).to be_nil
    end

    it "parseia inteiros e a faixa de casas", :aggregate_failures do
      d = described_class.parsear("Decimal[13.2-4]")

      expect(d.inteiros).to eq(13)
      expect(d.casas_minimas).to eq(2)
      expect(d.casas_maximas).to eq(4)
    end

    it "trata ponto sem casas como zero casas" do
      expect(described_class.parsear("Decimal[13.]").casas_maximas).to eq(0)
    end
  end

  describe "#validar" do
    subject(:decimal) { described_class.parsear("Decimal[13.2]") }

    it "aceita valor dentro de inteiros e casas" do
      expect(decimal.validar("10.50")).to be_nil
    end

    it "aceita menos casas que o mínimo" do
      expect(decimal.validar("10")).to be_nil
    end

    it "rejeita inteiros demais" do
      expect(described_class.parsear("Decimal[2.2]").validar("1234.5")).to include("inteiros")
    end

    it "rejeita casas decimais além do máximo" do
      expect(decimal.validar("10.123")).to include("casas")
    end

    it "rejeita valor não numérico" do
      expect(decimal.validar("abc")).to include("inválido")
    end
  end

  describe "#to_h" do
    it "descreve a especificação" do
      expect(described_class.parsear("Decimal[13.2-4]").to_h).to eq(
        inteiros: 13, casas_minimas: 2, casas_maximas: 4
      )
    end
  end
end
