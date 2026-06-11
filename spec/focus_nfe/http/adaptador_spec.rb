# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Adaptador do
  it "define #executar como interface abstrata, levantando NotImplementedError" do
    expect { described_class.new.executar(:get, "https://exemplo.test/x") }
      .to raise_error(NotImplementedError)
  end
end
