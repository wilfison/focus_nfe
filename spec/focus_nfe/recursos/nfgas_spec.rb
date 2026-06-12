# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfgas do
  it_behaves_like "um recurso emitível", "nfgas"
  it_behaves_like "um recurso consultável", "nfgas"
  it_behaves_like "um recurso cancelável", "nfgas"
end
