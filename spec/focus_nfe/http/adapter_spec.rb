# frozen_string_literal: true

RSpec.describe FocusNfe::HTTP::Adapter do
  it "define #call como interface abstrata, levantando NotImplementedError" do
    expect { described_class.new.call(:get, "https://exemplo.test/x") }
      .to raise_error(NotImplementedError)
  end
end
