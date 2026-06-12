# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de CT-e Outros Serviços (CT-e OS). Emissão síncrona com consulta
    # de estado e cancelamento.
    class CteOs < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "cte_os"
    end
  end
end
