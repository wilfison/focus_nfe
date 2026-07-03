# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal eletrônica (NF-e). Emissão assíncrona com consulta
    # de estado, cancelamento, Carta de Correção Eletrônica (CC-e), inutilização
    # de numeração e prévia da DANFe. Operações próprias da NF-e (eventos,
    # importação) chegam em fase posterior.
    class Nfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Corrigivel
      include Concerns::Inutilizavel
      include Concerns::Visualizavel
      include Concerns::Notificavel

      caminho_base "nfe"
      caminho_base_previa "nfe/danfe"
    end
  end
end
