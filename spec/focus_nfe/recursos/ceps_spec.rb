# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Ceps do
  it_behaves_like "um recurso listável", "ceps"
  it_behaves_like "um recurso localizável", "ceps"

  include_context "com recurso conectado"

  describe "#buscar" do
    it "é um apelido de #listar e devolve uma Pagina" do
      stub_get("ceps", query: { uf: "AM", logradouro: "Eduardo" }, body: "[]")

      expect(recurso.buscar(uf: "AM", logradouro: "Eduardo")).to be_a(FocusNfe::Modelos::Pagina)
    end
  end
end
