# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Cnaes do
  it_behaves_like "um recurso listável", "codigos_cnae"
  it_behaves_like "um recurso localizável", "codigos_cnae"

  include_context "com recurso conectado"

  it "usa o caminho_base 'codigos_cnae'" do
    expect(recurso.caminho_base).to eq("codigos_cnae")
  end

  describe "#buscar" do
    it "é um apelido de #listar" do
      stub_get("codigos_cnae", query: { descricao: "software" }, body: "[]")

      expect(recurso.buscar(descricao: "software")).to be_a(FocusNfe::Modelos::Pagina)
    end
  end
end
