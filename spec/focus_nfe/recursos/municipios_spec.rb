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
end
