# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::NfseNacional do
  it_behaves_like "um recurso emitível", "nfse_nacional"
  it_behaves_like "um recurso consultável", "nfse_nacional"
  it_behaves_like "um recurso cancelável", "nfse_nacional"
end
