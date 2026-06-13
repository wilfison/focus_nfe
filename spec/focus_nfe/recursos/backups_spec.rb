# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Backups do
  include_context "com recurso conectado"

  let(:cnpj) { "12345678000123" }

  it "usa o caminho_base 'backups'" do
    expect(recurso.caminho_base).to eq("backups")
  end

  describe "#consultar" do
    it "faz GET em /v2/backups/{cnpj}.json e devolve o corpo cru" do
      stub_get("backups/#{cnpj}.json", body: '[{"mes":"202605"}]')

      expect(recurso.consultar(cnpj)).to eq([{ "mes" => "202605" }])
    end

    it "escapa o cnpj, sem injetar query nem traversal no path" do
      stub_request(:get, /focusnfe/).to_return(status: 200, body: "[]", headers: json)

      recurso.consultar("../empresas/1?x=y")

      enviado = a_request(:get, /focusnfe/)
                .with { |req| req.uri.query.nil? && req.uri.path.include?("..%2Fempresas%2F1%3Fx") }
      expect(enviado).to have_been_made
    end
  end
end
