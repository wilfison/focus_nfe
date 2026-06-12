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

  describe "#validar com sub-esquemas aninhados" do
    subject(:validador) { described_class.new(esquema_topo, aninhados: { "modal_rodoviario" => sub_esquema }) }

    let(:esquema_topo) { FocusNfe::Esquemas::Esquema.new([]) }
    let(:sub_esquema) do
      FocusNfe::Esquemas::Esquema.new([{ "name" => "rntrc", "type" => "String[8]", "required" => true }])
    end

    it "não acusa nada quando o objeto aninhado é válido" do
      expect(validador.validar("modal_rodoviario" => { "rntrc" => "12345678" })).to eq([])
    end

    it "valida o objeto aninhado com chaves Symbol" do
      expect(validador.validar(modal_rodoviario: { rntrc: "12345678" })).to eq([])
    end

    it "prefixa os erros do aninhado com a chave" do
      erros = validador.validar("modal_rodoviario" => { "rntrc" => "1" })

      expect(erros.join).to include("modal_rodoviario.rntrc")
    end

    it "exige o objeto aninhado declarado" do
      expect(validador.validar({}).join).to include("modal_rodoviario: campo obrigatório ausente")
    end

    it "acusa quando o aninhado não é um objeto" do
      expect(validador.validar("modal_rodoviario" => "x").join).to include("modal_rodoviario: deve ser um objeto")
    end
  end
end
