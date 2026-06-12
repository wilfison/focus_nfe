# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfcom do
  it_behaves_like "um recurso emitível", "nfcom"
  it_behaves_like "um recurso consultável", "nfcom"
  it_behaves_like "um recurso cancelável", "nfcom"
end
