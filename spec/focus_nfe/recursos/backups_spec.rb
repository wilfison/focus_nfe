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
  end
end
