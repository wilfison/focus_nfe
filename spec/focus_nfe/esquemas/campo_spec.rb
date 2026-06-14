# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas::Campo do
  def campo(atributos)
    described_class.new(atributos)
  end

  describe "#nome e #obrigatorio?" do
    it "lê o nome e a obrigatoriedade da definição", :aggregate_failures do
      c = campo("name" => "natureza_operacao", "type" => "String[1-60]", "required" => true)

      expect(c.nome).to eq("natureza_operacao")
      expect(c).to be_obrigatorio
    end

    it "não é obrigatório quando required é false" do
      expect(campo("name" => "x", "type" => "String[1-60]", "required" => false)).not_to be_obrigatorio
    end
  end

  describe "parsing do tipo" do
    it "interpreta String[1-60] como string com mínimo e máximo", :aggregate_failures do
      c = campo("name" => "x", "type" => "String[1-60]")

      expect(c.tipo).to eq(:string)
      expect(c.tamanho_minimo).to eq(1)
      expect(c.tamanho_maximo).to eq(60)
    end

    it "interpreta String[14] como tamanho fixo", :aggregate_failures do
      c = campo("name" => "x", "type" => "String[14]")

      expect(c.tipo).to eq(:string)
      expect(c.tamanho_minimo).to eq(14)
      expect(c.tamanho_maximo).to eq(14)
    end

    it "interpreta Integer[1-9] como inteiro com faixa de dígitos", :aggregate_failures do
      c = campo("name" => "x", "type" => "Integer[1-9]")

      expect(c.tipo).to eq(:integer)
      expect(c.tamanho_minimo).to eq(1)
      expect(c.tamanho_maximo).to eq(9)
    end

    it "interpreta Decimal[13.2] como inteiros e casas fixas", :aggregate_failures do
      c = campo("name" => "x", "type" => "Decimal[13.2]")

      expect(c.tipo).to eq(:decimal)
      expect(c.decimal.inteiros).to eq(13)
      expect(c.decimal.casas_minimas).to eq(2)
      expect(c.decimal.casas_maximas).to eq(2)
    end

    it "interpreta Decimal[13.2-4] como faixa de casas", :aggregate_failures do
      c = campo("name" => "x", "type" => "Decimal[13.2-4]")

      expect(c.decimal.casas_minimas).to eq(2)
      expect(c.decimal.casas_maximas).to eq(4)
    end

    it "interpreta Decimal[13.] como zero casas", :aggregate_failures do
      c = campo("name" => "x", "type" => "Decimal[13.]")

      expect(c.decimal.inteiros).to eq(13)
      expect(c.decimal.casas_minimas).to eq(0)
      expect(c.decimal.casas_maximas).to eq(0)
    end

    it "interpreta Decimal[2] sem ponto como zero casas", :aggregate_failures do
      c = campo("name" => "x", "type" => "Decimal[2]")

      expect(c.decimal.inteiros).to eq(2)
      expect(c.decimal.casas_maximas).to eq(0)
    end

    it "interpreta Decimal[11.0-10] com casas a partir de zero", :aggregate_failures do
      c = campo("name" => "x", "type" => "Decimal[11.0-10]")

      expect(c.decimal.inteiros).to eq(11)
      expect(c.decimal.casas_minimas).to eq(0)
      expect(c.decimal.casas_maximas).to eq(10)
    end

    it "interpreta DateTime" do
      expect(campo("name" => "x", "type" => "DateTime").tipo).to eq(:datetime)
    end

    it "interpreta Date" do
      expect(campo("name" => "x", "type" => "Date").tipo).to eq(:date)
    end

    it "interpreta type nulo como enum quando há enum" do
      c = campo("name" => "x", "type" => nil, "enum" => "* +1+: Sim")

      expect(c.tipo).to eq(:enum)
    end

    it "marca coleções", :aggregate_failures do
      c = campo("name" => "items", "type" => "Coleção[1-990]", "collection" => { "object_attributes" => [] })

      expect(c).to be_colecao
      expect(c.tipo).to eq(:colecao)
    end
  end

  describe "#esquema_colecao" do
    let(:atributos) do
      [
        { "name" => "numero", "type" => "Integer[1-3]", "required" => true },
        { "name" => "descricao", "type" => "String[1-120]", "required" => true }
      ]
    end

    it "devolve nil para campo escalar" do
      expect(campo("name" => "x", "type" => "String[1-60]").esquema_colecao).to be_nil
    end

    it "devolve nil para coleção sem object_attributes" do
      expect(campo("name" => "x", "type" => "Coleção[0-5]", "collection" => {}).esquema_colecao).to be_nil
    end

    it "constrói um Esquema com os subcampos da coleção" do
      c = campo("name" => "items", "type" => "Coleção[1-990]", "collection" => { "object_attributes" => atributos })

      expect(c.esquema_colecao.campos.map(&:nome)).to eq(%w[numero descricao])
    end
  end

  describe "#to_h" do
    it "descreve um campo escalar com tipo, tamanho e metadados", :aggregate_failures do
      h = campo(
        "name" => "natureza_operacao", "description" => "Descrição da natureza de operação.",
        "type" => "String[1-60]", "required" => true, "tag" => "natOp"
      ).to_h

      expect(h).to include(
        nome: "natureza_operacao", descricao: "Descrição da natureza de operação.",
        tipo: :string, tipo_bruto: "String[1-60]", obrigatorio: true,
        tamanho_minimo: 1, tamanho_maximo: 60, enum: nil, tag: "natOp", colecao: nil
      )
    end

    it "expõe o enum e marca o tipo :enum", :aggregate_failures do
      h = campo("name" => "tipo_documento", "type" => nil, "enum" => "* +1+: Sim").to_h

      expect(h[:tipo]).to eq(:enum)
      expect(h[:enum]).to eq("* +1+: Sim")
    end

    it "aninha os subcampos de uma coleção em :colecao", :aggregate_failures do
      atributos = [{ "name" => "numero", "type" => "Integer[1-3]", "required" => true }]
      colecao = { "object_attributes" => atributos }
      h = campo("name" => "items", "type" => "Coleção[1-990]", "collection" => colecao).to_h

      expect(h[:tipo]).to eq(:colecao)
      expect(h[:colecao]).to eq([campo(atributos.first).to_h])
    end

    it "deixa :colecao nil para coleção sem object_attributes" do
      h = campo("name" => "x", "type" => "Coleção[0-5]", "collection" => {}).to_h

      expect(h[:colecao]).to be_nil
    end
  end

  describe "#validar_valor" do
    it "aceita string dentro do tamanho" do
      expect(campo("name" => "x", "type" => "String[1-60]").validar_valor("ok")).to be_nil
    end

    it "rejeita string acima do máximo" do
      mensagem = campo("name" => "natureza_operacao", "type" => "String[1-3]").validar_valor("abcd")

      expect(mensagem).to include("natureza_operacao")
    end

    it "rejeita inteiro com não-dígitos" do
      expect(campo("name" => "numero", "type" => "Integer[1-9]").validar_valor("12a")).to include("numero")
    end

    it "aceita inteiro válido na faixa de dígitos" do
      expect(campo("name" => "numero", "type" => "Integer[1-9]").validar_valor(12_345)).to be_nil
    end

    it "rejeita inteiro com quantidade de dígitos fora da faixa", :aggregate_failures do
      mensagem = campo("name" => "numero", "type" => "Integer[1-3]").validar_valor(12_345)

      expect(mensagem).to include("numero")
      expect(mensagem).to include("5 dígitos")
    end

    it "não restringe coleções nem tipos desconhecidos", :aggregate_failures do
      expect(campo("name" => "x", "type" => "Coleção[0-5]", "collection" => {}).validar_valor([])).to be_nil
      expect(campo("name" => "x", "type" => "Algo[1-2]").validar_valor("qualquer")).to be_nil
    end

    context "com decimais" do
      it "aceita decimal dentro de inteiros e casas" do
        expect(campo("name" => "valor", "type" => "Decimal[13.2]").validar_valor("10.50")).to be_nil
      end

      it "aceita menos casas que o mínimo" do
        expect(campo("name" => "valor", "type" => "Decimal[13.2]").validar_valor("10")).to be_nil
      end

      it "aceita Numeric além de String" do
        expect(campo("name" => "valor", "type" => "Decimal[13.2]").validar_valor(10.5)).to be_nil
      end

      it "rejeita inteiros demais", :aggregate_failures do
        mensagem = campo("name" => "valor", "type" => "Decimal[2.2]").validar_valor("1234.5")

        expect(mensagem).to include("valor")
      end

      it "rejeita casas decimais além do máximo" do
        expect(campo("name" => "valor", "type" => "Decimal[13.2]").validar_valor("10.123")).to include("valor")
      end

      it "rejeita valor não numérico" do
        expect(campo("name" => "valor", "type" => "Decimal[13.2]").validar_valor("abc")).to include("valor")
      end
    end

    context "com enums" do
      it "aceita valor dentro do conjunto declarado" do
        expect(campo("name" => "modalidade", "type" => nil, "enum" => "* +1+: Sim").validar_valor("1")).to be_nil
      end

      it "aceita Integer correspondente ao código String" do
        expect(campo("name" => "modalidade", "type" => nil, "enum" => "* +1+: Sim").validar_valor(1)).to be_nil
      end

      it "rejeita valor fora do conjunto" do
        c = campo("name" => "modalidade", "type" => nil, "enum" => "* +0+: Não\\n* +1+: Sim")

        expect(c.validar_valor("9")).to include("modalidade")
      end

      it "valida o conjunto mesmo quando o campo também tem tipo escalar" do
        c = campo("name" => "indicador", "type" => "Integer[1-1]", "enum" => "* +0+: Não\\n* +1+: Sim")

        expect(c.validar_valor(9)).to include("indicador")
      end

      it "rejeita o tipo escalar antes do enum" do
        c = campo("name" => "indicador", "type" => "Integer[1-1]", "enum" => "* +1+: Sim")

        expect(c.validar_valor("x")).to include("indicador")
      end
    end

    context "com datas" do
      it "aceita Date em ISO 8601" do
        expect(campo("name" => "data", "type" => "Date").validar_valor("2026-06-14")).to be_nil
      end

      it "rejeita Date inválida" do
        expect(campo("name" => "data", "type" => "Date").validar_valor("14/06/2026")).to include("data")
      end

      it "aceita DateTime com offset" do
        expect(campo("name" => "emissao", "type" => "DateTime").validar_valor("2026-06-14T10:00:00-03:00")).to be_nil
      end

      it "rejeita DateTime inválido" do
        expect(campo("name" => "emissao", "type" => "DateTime").validar_valor("qualquer")).to include("emissao")
      end
    end
  end

  describe "#valores_enum" do
    it "extrai códigos do formato com espaço" do
      c = campo("name" => "x", "type" => nil, "enum" => "* +0+: Correios\\n* +1+: Conta própria")

      expect(c.valores_enum).to eq(%w[0 1])
    end

    it "extrai códigos do formato sem espaço e multi-caractere" do
      c = campo("name" => "x", "type" => nil, "enum" => "*+01+: Repasse\\n*+99+: Outros")

      expect(c.valores_enum).to eq(%w[01 99])
    end

    it "devolve vazio para enum em branco", :aggregate_failures do
      expect(campo("name" => "x", "type" => "String[1-2]", "enum" => "").valores_enum).to eq([])
      expect(campo("name" => "x", "type" => "String[1-2]").enum?).to be(false)
    end
  end
end
