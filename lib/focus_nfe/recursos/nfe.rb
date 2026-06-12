# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal eletrônica (NF-e). Emissão assíncrona com consulta
    # de estado e cancelamento. Operações próprias da NF-e (CC-e, eventos,
    # inutilização, importação, prévia DANFe) chegam em fase posterior.
    class Nfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "nfe"
    end
  end
end
