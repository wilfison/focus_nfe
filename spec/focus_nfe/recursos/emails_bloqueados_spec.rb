# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::EmailsBloqueados do
  include_context "com recurso conectado"

  let(:email) { "bloqueado@exemplo.com" }

  it "usa o caminho_base 'blocked_emails'" do
    expect(recurso.caminho_base).to eq("blocked_emails")
  end

  describe "#consultar" do
    it "faz GET em /v2/blocked_emails/{email} e devolve o corpo cru" do
      stub_get("blocked_emails/#{email}", body: '{"block_type":"bounce"}')

      expect(recurso.consultar(email)).to eq("block_type" => "bounce")
    end
  end

  describe "#desbloquear" do
    it "faz DELETE em /v2/blocked_emails/{email}" do
      stub = stub_envio(:delete, "blocked_emails/#{email}")

      recurso.desbloquear(email)

      expect(stub).to have_been_requested
    end
  end
end
