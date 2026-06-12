# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas::Validador do
  subject(:validador) { described_class.new(esquema) }

  let(:esquema) do
    FocusNfe::Esquemas::Esquema.new(
      [
        { "name" => "natureza_operacao", "type" => "String[1-60]", "required" => true },
        { "name" => "serie", "type" => "String[1-3]", "required" => false },
        { "name" => "numero", "type" => "Integer[1-9]", "required" => false },
        { "name" => "items", "type" => "Coleção[1-990]", "required" => true,
          "collection" => { "object_attributes" => [valor_obrigatorio] } }
      ]
    )
  end

  let(:valor_obrigatorio) { { "name" => "valor", "type" => "Decimal[13.2]", "required" => true } }

  describe "#validar" do
    it "acusa campo obrigatório ausente" do
      erros = validador.validar("serie" => "1")

      expect(erros.join).to include("natureza_operacao")
    end

    it "acusa string acima do tamanho máximo" do
      erros = validador.validar("natureza_operacao" => "Venda", "serie" => "1234", "items" => [])

      expect(erros.join).to include("serie")
    end

    it "não acusa nada para um payload válido" do
      erros = validador.validar("natureza_operacao" => "Venda", "items" => [{ "valor" => "10.00" }])

      expect(erros).to eq([])
    end

    it "ignora o conteúdo de coleções (não recorre)" do
      erros = validador.validar("natureza_operacao" => "Venda", "items" => [{ "valor" => "x" }])

      expect(erros).to eq([])
    end

    it "aceita chaves String e Symbol no payload", :aggregate_failures do
      expect(validador.validar(natureza_operacao: "Venda", items: [])).to eq([])
      expect(validador.validar("natureza_operacao" => "Venda", "items" => [])).to eq([])
    end
  end

  describe "#validar!" do
    it "levanta ErroDeValidacao com a lista de erros", :aggregate_failures do
      expect { validador.validar!("serie" => "1") }.to raise_error(FocusNfe::Esquemas::ErroDeValidacao) do |erro|
        expect(erro.erros.join).to include("natureza_operacao")
        expect(erro.erros.join).to include("items")
      end
    end

    it "não levanta para payload válido" do
      expect { validador.validar!("natureza_operacao" => "Venda", "items" => []) }.not_to raise_error
    end
  end
end
