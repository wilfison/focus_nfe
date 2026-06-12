# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Dce do
  it_behaves_like "um recurso emitível", "dce"
  it_behaves_like "um recurso consultável", "dce"
  it_behaves_like "um recurso cancelável", "dce"
end
