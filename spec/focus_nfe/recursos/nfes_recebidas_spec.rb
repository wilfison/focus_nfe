# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::NfesRecebidas do
  include_context "com recurso conectado"

  let(:chave) { "35200114200166000187550010000000201234567890" }

  it_behaves_like "um recurso listável", "nfes_recebidas"
  it_behaves_like "um recurso baixável", "nfes_recebidas"
  it_behaves_like "um recurso notificável", "nfes_recebidas"

  describe "#consultar" do
    it "faz GET em /v2/nfes_recebidas/{chave} e devolve o corpo cru" do
      stub_get("nfes_recebidas/#{chave}", body: '{"situacao":"autorizada"}')

      expect(recurso.consultar(chave)).to eq("situacao" => "autorizada")
    end

    it "envia ?completa=1 quando completa: true" do
      stub = stub_get("nfes_recebidas/#{chave}", query: { completa: 1 })

      recurso.consultar(chave, completa: true)

      expect(stub).to have_been_requested
    end
  end

  describe "#manifestar" do
    it "faz POST em /{chave}/manifesto com tipo e justificativa" do
      corpo = '{"tipo":"ciencia","justificativa":"Ciente da operação."}'
      stub = stub_envio(:post, "nfes_recebidas/#{chave}/manifesto", body: corpo)

      recurso.manifestar(chave, tipo: "ciencia", justificativa: "Ciente da operação.")

      expect(stub).to have_been_requested
    end

    it "omite a justificativa quando não informada" do
      stub = stub_envio(:post, "nfes_recebidas/#{chave}/manifesto", body: '{"tipo":"confirmacao"}')

      recurso.manifestar(chave, tipo: "confirmacao")

      expect(stub).to have_been_requested
    end
  end

  describe "#emitir_evento" do
    it "faz POST em /{chave}/evento com tipo_evento e dados extras" do
      corpo = '{"tipo_evento":"imobilizacao_item","item":1}'
      stub = stub_envio(:post, "nfes_recebidas/#{chave}/evento", body: corpo)

      recurso.emitir_evento(chave, tipo_evento: "imobilizacao_item", item: 1)

      expect(stub).to have_been_requested
    end
  end

  describe "#cancelar_evento" do
    it "faz DELETE em /{chave}/evento" do
      stub = stub_envio(:delete, "nfes_recebidas/#{chave}/evento")

      recurso.cancelar_evento(chave)

      expect(stub).to have_been_requested
    end
  end
end
