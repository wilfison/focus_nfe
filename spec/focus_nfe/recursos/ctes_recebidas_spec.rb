# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::CtesRecebidas do
  include_context "com recurso conectado"

  let(:chave) { "35200114200166000187570010000000201234567890" }

  it_behaves_like "um recurso listável", "ctes_recebidas"
  it_behaves_like "um recurso baixável", "ctes_recebidas"
  it_behaves_like "um recurso notificável", "ctes_recebidas"

  describe "#consultar" do
    it "faz GET em /v2/ctes_recebidas/{chave} e devolve o corpo cru" do
      stub_get("ctes_recebidas/#{chave}", body: '{"situacao":"autorizado"}')

      expect(recurso.consultar(chave)).to eq("situacao" => "autorizado")
    end
  end

  describe "#desacordo" do
    it "faz POST em /{chave}/desacordo com as observações" do
      corpo = '{"observacoes":"Mercadoria não recebida conforme."}'
      stub = stub_envio(:post, "ctes_recebidas/#{chave}/desacordo", body: corpo)

      recurso.desacordo(chave, observacoes: "Mercadoria não recebida conforme.")

      expect(stub).to have_been_requested
    end
  end

  describe "#consultar_desacordo" do
    it "faz GET em /{chave}/desacordo e devolve o corpo cru" do
      stub_get("ctes_recebidas/#{chave}/desacordo", body: '{"status":"registrado"}')

      expect(recurso.consultar_desacordo(chave)).to eq("status" => "registrado")
    end
  end
end
