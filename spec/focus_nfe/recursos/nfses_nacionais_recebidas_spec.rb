# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::NfsesNacionaisRecebidas do
  it_behaves_like "um recurso listável", "nfsens_recebidas"
  it_behaves_like "um recurso baixável", "nfsens_recebidas"
  it_behaves_like "um recurso notificável", "nfsens_recebidas"

  include_context "com recurso conectado"

  describe "#baixar_html" do
    it "baixa o DANFSe em HTML cru" do
      stub_get("nfsens_recebidas/CHAVE.html", body: "<html></html>", headers: { "Content-Type" => "text/html" })

      expect(recurso.baixar_html("CHAVE")).to eq("<html></html>")
    end
  end
end
