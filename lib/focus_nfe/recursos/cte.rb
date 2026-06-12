# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Conhecimento de Transporte eletrônico (CT-e). Emissão
    # assíncrona (síncrona opcional) com consulta de estado e cancelamento.
    # Operações próprias (CC-e, modais) chegam em fase posterior.
    class Cte < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "cte"
    end
  end
end
