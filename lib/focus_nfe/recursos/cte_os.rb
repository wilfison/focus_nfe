# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de CT-e Outros Serviços (CT-e OS). Emissão síncrona com consulta
    # de estado e cancelamento.
    class CteOs < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "cte_os"

      # @return [Hash{String=>Hash{String=>String}}] código do modal => chave do payload => nome do sub-esquema
      MODAIS = {
        "01" => { "modal_rodoviario" => "cte_os_transporte_rodoviario" }
      }.freeze

      private

      # @see FocusNfe::Recursos::Base#esquemas_extras
      def esquemas_extras(dados)
        MODAIS.fetch(dados["modal"], {})
      end
    end
  end
end
