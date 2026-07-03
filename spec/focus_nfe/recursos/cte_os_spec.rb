# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::CteOs do
  it_behaves_like "um recurso emitível", "cte_os"
  it_behaves_like "um recurso consultável", "cte_os"
  it_behaves_like "um recurso cancelável", "cte_os"
  it_behaves_like "um recurso notificável", "cte_os"
end
