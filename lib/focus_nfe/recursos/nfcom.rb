# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal Fatura de Serviço de Comunicação eletrônica
    # (NFCom). Emissão assíncrona com consulta de estado e cancelamento.
    class Nfcom < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "nfcom"
    end
  end
end
