# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Authentication do
  it "produz o par { \"Authorization\" => \"Basic <base64>\" }", :aggregate_failures do
    header = described_class.header("abc")

    expect(header.keys).to eq(["Authorization"])
    expect(header["Authorization"]).to start_with("Basic ")
  end

  it "decodifica de volta para 'token:' — token como usuário, senha vazia", :aggregate_failures do
    value = described_class.header("meu-token").fetch("Authorization")
    decoded = value.delete_prefix("Basic ").unpack1("m0")

    expect(decoded).to eq("meu-token:")
    expect(decoded).to end_with(":")
  end

  it "gera Base64 sem quebra de linha (equivalente exato a strict_encode64)" do
    value = described_class.header("x").fetch("Authorization")

    expect(value).to eq("Basic eDo=")
  end
end
