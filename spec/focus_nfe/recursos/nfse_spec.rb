# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Nfse do
  it_behaves_like "um recurso emitível", "nfse"
  it_behaves_like "um recurso consultável", "nfse"
  it_behaves_like "um recurso cancelável", "nfse"
  it_behaves_like "um recurso notificável", "nfse"
  it_behaves_like "um recurso enviável por email", "nfse"
end
