# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Municipios do
  include_context "com recurso conectado"

  let(:codigo) { "1302603" }

  it_behaves_like "um recurso listável", "municipios"
  it_behaves_like "um recurso localizável", "municipios"

  describe "#listar_codigos_tributarios" do
    it "faz GET no sub-recurso de códigos tributários e devolve uma Pagina" do
      stub_get("municipios/#{codigo}/codigos_tributarios_municipio", body: "[]")

      expect(recurso.listar_codigos_tributarios(codigo)).to be_a(FocusNfe::Modelos::Pagina)
    end

    it "repassa os filtros como query string" do
      stub = stub_get("municipios/#{codigo}/codigos_tributarios_municipio", query: { offset: 50 })

      recurso.listar_codigos_tributarios(codigo, offset: 50)

      expect(stub).to have_been_requested
    end
  end

  describe "#listar_itens_lista_servico" do
    it "faz GET no sub-recurso de itens da lista de serviço e devolve uma Pagina" do
      stub_get("municipios/#{codigo}/itens_lista_servico", body: "[]")

      expect(recurso.listar_itens_lista_servico(codigo)).to be_a(FocusNfe::Modelos::Pagina)
    end
  end

  describe "#consultar_codigo_tributario" do
    it "faz GET no código tributário por código e devolve o corpo cru" do
      stub_get("municipios/#{codigo}/codigos_tributarios_municipio/1.06", body: '{"codigo":"1.06"}')

      expect(recurso.consultar_codigo_tributario(codigo, "1.06")).to eq("codigo" => "1.06")
    end
  end

  describe "#consultar_item_lista_servico" do
    it "faz GET no item da lista de serviço por código e devolve o corpo cru" do
      stub_get("municipios/#{codigo}/itens_lista_servico/1.06", body: '{"codigo":"1.06"}')

      expect(recurso.consultar_item_lista_servico(codigo, "1.06")).to eq("codigo" => "1.06")
    end
  end

  describe "#consultar_json" do
    it "faz GET no JSON de exemplo do município e devolve o corpo cru" do
      stub_get("municipios/#{codigo}/json", body: '{"prestador":{}}')

      expect(recurso.consultar_json(codigo)).to eq("prestador" => {})
    end
  end
end
