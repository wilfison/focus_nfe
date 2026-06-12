# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Ncms do
  it_behaves_like "um recurso listável", "ncms"
  it_behaves_like "um recurso localizável", "ncms"

  include_context "com recurso conectado"

  describe "#buscar" do
    it "é um apelido de #listar" do
      stub_get("ncms", query: { capitulo: "85" }, body: "[]")

      expect(recurso.buscar(capitulo: "85")).to be_a(FocusNfe::Modelos::Pagina)
    end
  end
end
