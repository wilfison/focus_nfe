# frozen_string_literal: true

RSpec.describe FocusNfe::Modelos::Pagina do
  def response(body:, headers: {})
    FocusNfe::HTTP::Response.new(
      status: 200,
      headers: { "Content-Type" => "application/json" }.merge(headers),
      body: JSON.generate(body)
    )
  end

  describe ".from_response" do
    it "expõe os itens do corpo (Array)" do
      pagina = described_class.from_response(response(body: [{ "a" => 1 }, { "a" => 2 }]))

      expect(pagina.itens).to eq([{ "a" => 1 }, { "a" => 2 }])
    end

    it "usa lista vazia quando o corpo não é um Array" do
      pagina = described_class.from_response(response(body: { "erro" => "x" }))

      expect(pagina.itens).to eq([])
    end

    it "lê total e versao_maxima dos headers de paginação", :aggregate_failures do
      pagina = described_class.from_response(
        response(body: [], headers: { "X-Total-Count" => "42", "X-Max-Version" => "7" })
      )

      expect(pagina.total).to eq(42)
      expect(pagina.versao_maxima).to eq(7)
    end

    it "deixa total e versao_maxima nil quando os headers estão ausentes", :aggregate_failures do
      pagina = described_class.from_response(response(body: []))

      expect(pagina.total).to be_nil
      expect(pagina.versao_maxima).to be_nil
    end

    it "guarda a resposta original" do
      resp = response(body: [])

      expect(described_class.from_response(resp).response).to be(resp)
    end
  end

  describe "enumerável" do
    subject(:pagina) { described_class.from_response(response(body: [1, 2, 3])) }

    it "itera com cada", :aggregate_failures do
      coletados = []
      retorno = pagina.cada { |item| coletados << item }

      expect(coletados).to eq([1, 2, 3])
      expect(retorno).to be(pagina)
    end

    it "compõe os helpers de Enumerable (map/select)", :aggregate_failures do
      expect(pagina.map { |i| i * 2 }).to eq([2, 4, 6])
      expect(pagina.select(&:even?)).to eq([2])
    end

    it "devolve um Enumerator quando chamado sem bloco", :aggregate_failures do
      enum = pagina.cada

      expect(enum).to be_a(Enumerator)
      expect(enum.to_a).to eq([1, 2, 3])
    end
  end

  describe "imutabilidade" do
    it "congela a instância" do
      expect(described_class.from_response(response(body: []))).to be_frozen
    end
  end
end
