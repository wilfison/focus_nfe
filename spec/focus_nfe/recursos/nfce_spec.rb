# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfce do
  it_behaves_like "um recurso emitível", "nfce"
  it_behaves_like "um recurso consultável", "nfce"
  it_behaves_like "um recurso cancelável", "nfce"
end
