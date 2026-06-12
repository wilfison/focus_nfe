# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Manifesto Eletrônico de Documentos Fiscais (MDF-e). Emissão
    # assíncrona com consulta de estado e cancelamento. Operações próprias
    # (encerramento, eventos de manifesto, modais) chegam em fase posterior.
    class Mdfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "mdfe"
    end
  end
end
