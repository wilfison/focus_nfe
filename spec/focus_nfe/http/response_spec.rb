# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Response do
  def build(status: 200, headers: {}, body: nil)
    described_class.new(status: status, headers: headers, body: body)
  end

  describe "atributos" do
    it "expõe status, headers, body e raw_body", :aggregate_failures do
      response = build(status: 201, headers: { "Content-Type" => "application/json" }, body: '{"ref":"abc"}')

      expect(response.status).to eq(201)
      expect(response.headers["Content-Type"]).to eq("application/json")
      expect(response.body).to eq("ref" => "abc")
      expect(response.raw_body).to eq('{"ref":"abc"}')
    end
  end

  describe "imutabilidade" do
    it "congela a instância" do
      expect(build).to be_frozen
    end

    it "congela o conjunto de cabeçalhos" do
      response = build(headers: { "Content-Type" => "application/json" })

      expect(response.headers).to be_frozen
    end

    it "não expõe escritores de atributos", :aggregate_failures do
      response = build

      expect(response).not_to respond_to(:status=)
      expect(response).not_to respond_to(:body=)
    end
  end

  describe "#success?" do
    it "é verdadeiro para status 2xx", :aggregate_failures do
      expect(build(status: 200)).to be_success
      expect(build(status: 204)).to be_success
      expect(build(status: 299)).to be_success
    end

    it "é falso fora da faixa 2xx", :aggregate_failures do
      expect(build(status: 199)).not_to be_success
      expect(build(status: 301)).not_to be_success
      expect(build(status: 404)).not_to be_success
      expect(build(status: 500)).not_to be_success
    end
  end

  describe "#body" do
    it "parseia JSON quando o Content-Type indica JSON" do
      response = build(
        headers: { "Content-Type" => "application/json; charset=utf-8" },
        body: '{"status":"autorizado","itens":[1,2]}'
      )

      expect(response.body).to eq("status" => "autorizado", "itens" => [1, 2])
    end

    it "parseia arrays JSON" do
      response = build(
        headers: { "Content-Type" => "application/json" },
        body: "[1,2,3]"
      )

      expect(response.body).to eq([1, 2, 3])
    end

    it "devolve a string crua quando não é JSON" do
      response = build(
        headers: { "Content-Type" => "application/xml" },
        body: "<nfe>...</nfe>"
      )

      expect(response.body).to eq("<nfe>...</nfe>")
    end

    it "devolve a string crua quando não há Content-Type" do
      response = build(body: "texto puro")

      expect(response.body).to eq("texto puro")
    end

    it "cai para o corpo cru quando o JSON é inválido, sem levantar" do
      response = build(
        headers: { "Content-Type" => "application/json" },
        body: "{invalido"
      )

      expect(response.body).to eq("{invalido")
    end

    it "devolve nil quando o corpo JSON é vazio" do
      response = build(
        headers: { "Content-Type" => "application/json" },
        body: ""
      )

      expect(response.body).to be_nil
    end

    it "é calculado uma vez (mesmo objeto a cada leitura)" do
      response = build(
        headers: { "Content-Type" => "application/json" },
        body: '{"ref":"abc"}'
      )

      expect(response.body).to equal(response.body)
    end
  end

  describe "#raw_body" do
    it "devolve sempre a string original, mesmo com JSON válido" do
      response = build(
        headers: { "Content-Type" => "application/json" },
        body: '{"ref":"abc"}'
      )

      expect(response.raw_body).to eq('{"ref":"abc"}')
    end
  end

  describe "leitura de cabeçalhos case-insensitive" do
    it "encontra o cabeçalho independentemente do caso usado na busca", :aggregate_failures do
      response = build(headers: { "Content-Type" => "application/json" })

      expect(response.headers["content-type"]).to eq("application/json")
      expect(response.headers["CONTENT-TYPE"]).to eq("application/json")
      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "encontra o cabeçalho independentemente do caso recebido na origem" do
      response = build(headers: { "content-type" => "application/json" })

      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "detecta JSON mesmo quando o Content-Type chega em minúsculas" do
      response = build(
        headers: { "content-type" => "application/json" },
        body: '{"ok":true}'
      )

      expect(response.body).to eq("ok" => true)
    end

    it "devolve nil para cabeçalho ausente" do
      expect(build.headers["X-Inexistente"]).to be_nil
    end

    it "expõe os cabeçalhos normalizados via #to_h", :aggregate_failures do
      copia = build(headers: { "Content-Type" => "application/json" }).headers.to_h

      expect(copia).to eq("content-type" => "application/json")
      expect(copia).not_to be_frozen
    end
  end
end
