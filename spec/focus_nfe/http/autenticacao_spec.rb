# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Autenticacao do
  it "produz o par { \"Authorization\" => \"Basic <base64>\" }", :aggregate_failures do
    cabecalho = described_class.cabecalho("abc")

    expect(cabecalho.keys).to eq(["Authorization"])
    expect(cabecalho["Authorization"]).to start_with("Basic ")
  end

  it "decodifica de volta para 'token:' — token como usuário, senha vazia", :aggregate_failures do
    valor = described_class.cabecalho("meu-token").fetch("Authorization")
    decodificado = valor.delete_prefix("Basic ").unpack1("m0")

    expect(decodificado).to eq("meu-token:")
    expect(decodificado).to end_with(":")
  end

  it "gera Base64 sem quebra de linha (equivalente exato a strict_encode64)" do
    valor = described_class.cabecalho("x").fetch("Authorization")

    expect(valor).to eq("Basic eDo=")
  end
end
