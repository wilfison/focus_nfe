# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de reenvio do documento por e-mail (+POST
      # /<base>/<ref>/email+ com a lista de destinatários no corpo). Devolve o
      # corpo cru da resposta.
      module Enviavel
        # @return [Integer] número máximo de destinatários aceito pela API
        MAX_EMAILS = 10

        # Reenvia o documento por e-mail para os destinatários informados.
        #
        # @param ref [String] referência do documento
        # @param emails [Array<String>] destinatários (1 a 10)
        # @return [Hash, Array, nil] corpo cru da resposta
        # @raise [ArgumentError] se a +ref+ ou a lista de +emails+ forem inválidas
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def enviar_email(ref, emails:)
          validar_referencia!(ref)
          validar_emails!(emails)

          connection.post("#{caminho_referencia(ref)}/email", body: { emails: emails }).body
        end

        private

        # @param emails [Array<String>] lista informada
        # @return [void]
        # @raise [ArgumentError] se não for Array de 1 a 10 elementos
        def validar_emails!(emails)
          return if emails.is_a?(Array) && (1..MAX_EMAILS).cover?(emails.size)

          raise ArgumentError, "emails inválidos: esperado Array com 1 a #{MAX_EMAILS} destinatários"
        end
      end
    end
  end
end
