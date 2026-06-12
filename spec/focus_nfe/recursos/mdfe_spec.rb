# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Mdfe do
  it_behaves_like "um recurso emitível", "mdfe"
  it_behaves_like "um recurso consultável", "mdfe"
  it_behaves_like "um recurso cancelável", "mdfe"
end
