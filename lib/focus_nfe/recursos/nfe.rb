# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal eletrônica (NF-e). Emissão assíncrona com consulta
    # de estado, cancelamento, Carta de Correção Eletrônica (CC-e) e inutilização
    # de numeração. Operações próprias da NF-e (eventos, importação, prévia DANFe)
    # chegam em fase posterior.
    class Nfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Corrigivel
      include Concerns::Inutilizavel

      caminho_base "nfe"
    end
  end
end
