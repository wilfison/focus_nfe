# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de emissão (+POST /<base>?ref=+). Devolve o {Modelos::Documento}
      # com o estado fiscal inicial (em geral assíncrono: +processando_autorizacao+).
      module Emitivel
        # Emite um documento fiscal.
        #
        # @param ref [String] referência única do documento na sua aplicação
        # @param dados [Hash] payload de emissão (campos do schema, validados server-side)
        # @param opcoes [Hash] parâmetros de query adicionais (ex.: emissão síncrona)
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def emitir(ref:, dados:, **opcoes)
          validar_referencia!(ref)

          response = connection.post(caminho_base, params: { ref: ref, **opcoes }, body: dados)
          Modelos::Documento.from_response(response, ref: ref)
        end
      end
    end
  end
end
