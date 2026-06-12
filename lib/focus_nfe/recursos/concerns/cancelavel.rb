# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de cancelamento (+DELETE /<base>/{ref}+ com +justificativa+ no
      # corpo). Devolve o {Modelos::Documento} com o estado fiscal resultante.
      module Cancelavel
        # Cancela um documento já emitido.
        #
        # @param ref [String] referência do documento
        # @param justificativa [String] motivo do cancelamento exigido pela SEFAZ
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def cancelar(ref, justificativa:)
          validar_referencia!(ref)

          response = connection.delete(caminho_referencia(ref), body: { justificativa: justificativa })
          Modelos::Documento.from_response(response, ref: ref)
        end
      end
    end
  end
end
