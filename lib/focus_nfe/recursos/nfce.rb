# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal de Consumidor eletrônica (NFC-e). Emissão síncrona
    # com consulta de estado, cancelamento e inutilização de numeração. Operações
    # próprias (contingência offline, ECONF) chegam em fase posterior. A NFC-e não
    # admite Carta de Correção.
    class Nfce < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Inutilizavel

      caminho_base "nfce"
    end
  end
end
