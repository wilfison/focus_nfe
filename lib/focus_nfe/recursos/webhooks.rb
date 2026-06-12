# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Gestão de webhooks (gatilhos de notificação). O caminho da API é +hooks+.
    class Webhooks < Base
      include Concerns::Listavel
      include Concerns::Localizavel
      include Concerns::Removivel

      caminho_base "hooks"

      # Cria um webhook.
      #
      # @param dados [Hash] dados do gatilho (+event+, +url+, +cnpj+, …)
      # @return [Hash] corpo cru da resposta
      def criar(dados:)
        connection.post(caminho_base, body: dados).body
      end
    end
  end
end
