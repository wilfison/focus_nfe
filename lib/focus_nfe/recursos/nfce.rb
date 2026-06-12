# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal de Consumidor eletrônica (NFC-e). Emissão síncrona
    # com consulta de estado e cancelamento. Operações próprias (contingência
    # offline, ECONF, inutilização) chegam em fase posterior.
    class Nfce < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "nfce"
    end
  end
end
