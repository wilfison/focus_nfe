# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Conhecimento de Transporte eletrônico (CT-e). Emissão
    # assíncrona (síncrona opcional) com consulta de estado, cancelamento e
    # Carta de Correção Eletrônica (CC-e) por campo.
    class Cte < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::CorrigivelCte
      include Concerns::Notificavel

      caminho_base "cte"

      # @return [Hash{String=>Hash{String=>String}}] código do modal => chave do payload => nome do sub-esquema
      MODAIS = {
        "01" => { "modal_rodoviario" => "cte_transporte_rodoviario" },
        "02" => { "modal_aereo" => "cte_transporte_aereo" },
        "03" => { "modal_aquaviario" => "cte_transporte_aquaviario" },
        "04" => { "modal_ferroviario" => "cte_transporte_ferroviario" },
        "05" => { "modal_dutoviario" => "cte_transporte_dutoviario" },
        "06" => { "modal_multimodal" => "cte_transporte_multimodal" }
      }.freeze

      private

      # @see FocusNfe::Recursos::Base#esquemas_extras
      def esquemas_extras(dados)
        MODAIS.fetch(dados["modal"], {})
      end
    end
  end
end
