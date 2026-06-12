# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Declaração de Conteúdo eletrônica (DC-e). Emissão assíncrona
    # com consulta de estado e cancelamento.
    class Dce < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "dce"
    end
  end
end
