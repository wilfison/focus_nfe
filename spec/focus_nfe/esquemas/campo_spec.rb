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

    it "interpreta Decimal[13.2] como decimal" do
      expect(campo("name" => "x", "type" => "Decimal[13.2]").tipo).to eq(:decimal)
    end

    it "interpreta DateTime" do
      expect(campo("name" => "x", "type" => "DateTime").tipo).to eq(:datetime)
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

    it "não restringe enums, datetime, coleções nem tipos desconhecidos", :aggregate_failures do
      expect(campo("name" => "x", "type" => nil, "enum" => "* +1+: Sim").validar_valor("9")).to be_nil
      expect(campo("name" => "x", "type" => "DateTime").validar_valor("qualquer")).to be_nil
      expect(campo("name" => "x", "type" => "Coleção[0-5]", "collection" => {}).validar_valor([])).to be_nil
    end
  end
end
