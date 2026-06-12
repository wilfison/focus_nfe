# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Gestão de e-mails bloqueados (bounces/reclamações). O caminho da API é
    # +blocked_emails+; o e-mail compõe o path e é escapado.
    class EmailsBloqueados < Base
      caminho_base "blocked_emails"

      # @param email [String] e-mail a consultar
      # @return [Hash] corpo cru da resposta com o motivo do bloqueio
      def consultar(email)
        connection.get(caminho_email(email)).body
      end

      # Solicita o desbloqueio (exclusão) de um e-mail.
      #
      # @param email [String] e-mail a desbloquear
      # @return [Hash] corpo cru da resposta
      def desbloquear(email)
        connection.delete(caminho_email(email)).body
      end

      private

      def caminho_email(email)
        "#{caminho_base}/#{URI.encode_www_form_component(email)}"
      end
    end
  end
end
