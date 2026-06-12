# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Empresas do
  include_context "com recurso conectado"

  let(:dados) { { "nome" => "Loja", "cnpj" => "12345678000123" } }

  it_behaves_like "um recurso listável", "empresas"
  it_behaves_like "um recurso localizável", "empresas"
  it_behaves_like "um recurso removível", "empresas"

  describe "#criar" do
    it "faz POST em /v2/empresas com os dados e devolve o corpo cru" do
      stub_envio(:post, "empresas", body: JSON.generate(dados), resposta: '{"id":1}')

      expect(recurso.criar(dados: dados)).to eq("id" => 1)
    end

    it "inclui dry_run=1 na query quando dry_run: true" do
      stub = stub_envio(:post, "empresas", query: { dry_run: 1 }, body: JSON.generate(dados))

      recurso.criar(dados: dados, dry_run: true)

      expect(stub).to have_been_requested
    end

    it "não envia dry_run por padrão" do
      stub = stub_envio(:post, "empresas", body: JSON.generate(dados))

      recurso.criar(dados: dados)

      expect(stub).to have_been_requested
    end
  end

  describe "#atualizar" do
    it "faz PUT em /v2/empresas/{id} com os dados" do
      stub = stub_envio(:put, "empresas/7", body: JSON.generate(dados))

      recurso.atualizar("7", dados: dados)

      expect(stub).to have_been_requested
    end
  end
end
