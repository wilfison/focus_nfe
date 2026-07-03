# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal de Gás eletrônica (NFGas, em beta). Emissão
    # assíncrona com consulta de estado e cancelamento.
    class Nfgas < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Notificavel

      caminho_base "nfgas"
    end
  end
end
