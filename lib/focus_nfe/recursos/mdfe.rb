# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Manifesto Eletrônico de Documentos Fiscais (MDF-e). Emissão
    # assíncrona com consulta de estado e cancelamento. Operações próprias
    # (encerramento, eventos de manifesto, modais) chegam em fase posterior.
    class Mdfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "mdfe"

      MODAIS = {
        "modal_rodoviario" => "mdfe_transporte_rodoviario",
        "modal_aereo" => "mdfe_transporte_aereo",
        "modal_aquaviario" => "mdfe_transporte_aquaviario",
        "modal_ferroviario" => "mdfe_transporte_ferroviario"
      }.freeze

      private

      # A MDFe não possui campo +modal+: o modal é deduzido pela chave
      # +modal_<tipo>+ presente no payload.
      #
      # @see FocusNfe::Recursos::Base#esquemas_extras
      def esquemas_extras(dados)
        MODAIS.select { |chave, _| dados.key?(chave) }
      end
    end
  end
end
