# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal de Consumidor eletrônica (NFC-e). Emissão síncrona
    # com consulta de estado, cancelamento, inutilização de numeração, envio por
    # e-mail e conciliação financeira (ECONF). A NFC-e não admite Carta de Correção.
    class Nfce < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Inutilizavel
      include Concerns::Enviavel
      include Concerns::Conciliavel

      caminho_base "nfce"
    end
  end
end
