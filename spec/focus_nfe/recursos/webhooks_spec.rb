# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Webhooks do
  include_context "com recurso conectado"

  it_behaves_like "um recurso listável", "hooks"
  it_behaves_like "um recurso localizável", "hooks"
  it_behaves_like "um recurso removível", "hooks"

  it "usa o caminho_base 'hooks'" do
    expect(recurso.caminho_base).to eq("hooks")
  end

  describe "#criar" do
    it "faz POST em /v2/hooks com os dados e devolve o corpo cru" do
      dados = { "event" => "nfe", "url" => "https://meu.app/hooks/nfe" }
      stub_envio(:post, "hooks", body: JSON.generate(dados), resposta: '{"id":9}')

      expect(recurso.criar(dados: dados)).to eq("id" => 9)
    end
  end
end
