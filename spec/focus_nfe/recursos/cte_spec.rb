# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Cte do
  it_behaves_like "um recurso emitível", "cte"
  it_behaves_like "um recurso consultável", "cte"
  it_behaves_like "um recurso cancelável", "cte"
  it_behaves_like "um recurso corrigível por campo", "cte"
  it_behaves_like "um recurso notificável", "cte"
end
