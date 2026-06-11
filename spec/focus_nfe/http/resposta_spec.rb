# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Resposta do
  def construir(status: 200, cabecalhos: {}, corpo: nil)
    described_class.new(status: status, cabecalhos: cabecalhos, corpo: corpo)
  end

  describe "atributos" do
    it "expõe status, cabecalhos, corpo e corpo_cru", :aggregate_failures do
      resposta = construir(status: 201, cabecalhos: { "Content-Type" => "application/json" }, corpo: '{"ref":"abc"}')

      expect(resposta.status).to eq(201)
      expect(resposta.cabecalhos["Content-Type"]).to eq("application/json")
      expect(resposta.corpo).to eq("ref" => "abc")
      expect(resposta.corpo_cru).to eq('{"ref":"abc"}')
    end
  end

  describe "imutabilidade" do
    it "congela a instância" do
      expect(construir).to be_frozen
    end

    it "congela o conjunto de cabeçalhos" do
      resposta = construir(cabecalhos: { "Content-Type" => "application/json" })

      expect(resposta.cabecalhos).to be_frozen
    end

    it "não expõe escritores de atributos", :aggregate_failures do
      resposta = construir

      expect(resposta).not_to respond_to(:status=)
      expect(resposta).not_to respond_to(:corpo=)
    end
  end

  describe "#sucesso?" do
    it "é verdadeiro para status 2xx", :aggregate_failures do
      expect(construir(status: 200)).to be_sucesso
      expect(construir(status: 204)).to be_sucesso
      expect(construir(status: 299)).to be_sucesso
    end

    it "é falso fora da faixa 2xx", :aggregate_failures do
      expect(construir(status: 199)).not_to be_sucesso
      expect(construir(status: 301)).not_to be_sucesso
      expect(construir(status: 404)).not_to be_sucesso
      expect(construir(status: 500)).not_to be_sucesso
    end
  end

  describe "#corpo" do
    it "parseia JSON quando o Content-Type indica JSON" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json; charset=utf-8" },
        corpo: '{"status":"autorizado","itens":[1,2]}'
      )

      expect(resposta.corpo).to eq("status" => "autorizado", "itens" => [1, 2])
    end

    it "parseia arrays JSON" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: "[1,2,3]"
      )

      expect(resposta.corpo).to eq([1, 2, 3])
    end

    it "devolve a string crua quando não é JSON" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/xml" },
        corpo: "<nfe>...</nfe>"
      )

      expect(resposta.corpo).to eq("<nfe>...</nfe>")
    end

    it "devolve a string crua quando não há Content-Type" do
      resposta = construir(corpo: "texto puro")

      expect(resposta.corpo).to eq("texto puro")
    end

    it "cai para o corpo cru quando o JSON é inválido, sem levantar" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: "{invalido"
      )

      expect(resposta.corpo).to eq("{invalido")
    end

    it "devolve nil quando o corpo JSON é vazio" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: ""
      )

      expect(resposta.corpo).to be_nil
    end

    it "é calculado uma vez (mesmo objeto a cada leitura)" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: '{"ref":"abc"}'
      )

      expect(resposta.corpo).to equal(resposta.corpo)
    end
  end

  describe "#corpo_cru" do
    it "devolve sempre a string original, mesmo com JSON válido" do
      resposta = construir(
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: '{"ref":"abc"}'
      )

      expect(resposta.corpo_cru).to eq('{"ref":"abc"}')
    end
  end

  describe "leitura de cabeçalhos case-insensitive" do
    it "encontra o cabeçalho independentemente do caso usado na busca", :aggregate_failures do
      resposta = construir(cabecalhos: { "Content-Type" => "application/json" })

      expect(resposta.cabecalhos["content-type"]).to eq("application/json")
      expect(resposta.cabecalhos["CONTENT-TYPE"]).to eq("application/json")
      expect(resposta.cabecalhos["Content-Type"]).to eq("application/json")
    end

    it "encontra o cabeçalho independentemente do caso recebido na origem" do
      resposta = construir(cabecalhos: { "content-type" => "application/json" })

      expect(resposta.cabecalhos["Content-Type"]).to eq("application/json")
    end

    it "detecta JSON mesmo quando o Content-Type chega em minúsculas" do
      resposta = construir(
        cabecalhos: { "content-type" => "application/json" },
        corpo: '{"ok":true}'
      )

      expect(resposta.corpo).to eq("ok" => true)
    end

    it "devolve nil para cabeçalho ausente" do
      expect(construir.cabecalhos["X-Inexistente"]).to be_nil
    end
  end
end
