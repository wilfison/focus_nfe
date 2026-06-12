# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Cfops do
  it_behaves_like "um recurso listável", "cfops"
  it_behaves_like "um recurso localizável", "cfops"

  include_context "com recurso conectado"

  describe "#buscar" do
    it "é um apelido de #listar" do
      stub_get("cfops", query: { descricao: "venda" }, body: "[]")

      expect(recurso.buscar(descricao: "venda")).to be_a(FocusNfe::Modelos::Pagina)
    end
  end
end
