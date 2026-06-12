# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Cnpjs do
  it_behaves_like "um recurso localizável", "cnpjs"

  include_context "com recurso conectado"

  it "não expõe listagem" do
    expect(recurso).not_to respond_to(:listar)
  end
end
