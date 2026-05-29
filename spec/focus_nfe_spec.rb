# frozen_string_literal: true

RSpec.describe FocusNfe do
  it "possui um número de versão" do
    expect(FocusNfe::VERSION).not_to be_nil
  end

  it "define uma classe de erro base" do
    expect(FocusNfe::Error.new).to be_a(StandardError)
  end
end
