# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de reenvio de notificação (+POST /<base>/<identificador>/hook+),
      # disparando de novo o webhook do documento.
      module Notificavel
        # Reenvia a notificação (webhook) do documento.
        #
        # @param identificador [String] chave ou referência do documento
        # @return [Hash, Array, nil] corpo cru da resposta
        # @raise [ArgumentError] se o +identificador+ for inválido
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def reenviar_hook(identificador)
          validar_referencia!(identificador)

          connection.post("#{caminho_referencia(identificador)}/hook").body
        end
      end
    end
  end
end
