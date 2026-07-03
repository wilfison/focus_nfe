# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Conhecimentos de transporte (CT-e) recebidos contra um CNPJ. Listagem com
    # sincronização incremental, consulta por chave, downloads e prestação de
    # desacordo de serviço.
    class CtesRecebidas < Base
      include Concerns::Listavel
      include Concerns::Baixavel
      include Concerns::Notificavel

      caminho_base "ctes_recebidas"

      # @param chave [String] chave de acesso do CT-e
      # @return [Hash] corpo cru da resposta
      def consultar(chave)
        connection.get(caminho_referencia(chave)).body
      end

      # Registra a prestação de desacordo do serviço de transporte.
      #
      # @param chave [String] chave de acesso do CT-e
      # @param observacoes [String] motivo do desacordo (15 a 255 caracteres)
      # @return [Hash] corpo cru da resposta
      def desacordo(chave, observacoes:)
        connection.post("#{caminho_referencia(chave)}/desacordo", body: { observacoes: observacoes }).body
      end

      # @param chave [String] chave de acesso do CT-e
      # @return [Hash] corpo cru da resposta com o desacordo registrado
      def consultar_desacordo(chave)
        connection.get("#{caminho_referencia(chave)}/desacordo").body
      end

      # @param chave [String] chave de acesso do CT-e
      # @return [String, nil] XML do último cancelamento
      def baixar_xml_cancelamento(chave)
        connection.get("#{caminho_referencia(chave)}/cancelamento.xml").raw_body
      end

      # @param chave [String] chave de acesso do CT-e
      # @return [String, nil] XML da última carta de correção
      def baixar_xml_carta_correcao(chave)
        connection.get("#{caminho_referencia(chave)}/carta_correcao.xml").raw_body
      end
    end
  end
end
