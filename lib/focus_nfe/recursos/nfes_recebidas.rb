# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Notas fiscais (NF-e) recebidas contra um CNPJ. Listagem com sincronização
    # incremental, consulta por chave, downloads, manifestação do destinatário e
    # eventos.
    class NfesRecebidas < Base
      include Concerns::Listavel
      include Concerns::Baixavel
      include Concerns::BaixavelEventos
      include Concerns::Notificavel
      include Concerns::Eventavel

      caminho_base "nfes_recebidas"

      # @param chave [String] chave de acesso da NF-e
      # @param completa [Boolean] quando +true+, pede a resposta completa (+completa=1+)
      # @return [Hash] corpo cru da resposta
      def consultar(chave, completa: false)
        params = completa ? { completa: 1 } : {}
        connection.get(caminho_referencia(chave), params: params).body
      end

      # Registra a manifestação do destinatário.
      #
      # @param chave [String] chave de acesso da NF-e
      # @param tipo [String] +ciencia+/+confirmacao+/+desconhecimento+/+nao_realizada+
      # @param justificativa [String, nil] obrigatória apenas para +nao_realizada+
      # @return [Hash] corpo cru da resposta
      def manifestar(chave, tipo:, justificativa: nil)
        corpo = { tipo: tipo }
        corpo[:justificativa] = justificativa unless justificativa.nil?
        connection.post("#{caminho_referencia(chave)}/manifesto", body: corpo).body
      end

      # Emite um evento sobre a NF-e recebida.
      #
      # @param chave [String] chave de acesso da NF-e
      # @param tipo_evento [String] tipo do evento suportado pela API
      # @param dados [Hash] campos adicionais do evento
      # @return [FocusNfe::Modelos::Documento]
      def emitir_evento(chave, tipo_evento:, **dados)
        emitir_evento_em(chave, caminho: "evento", tipo_evento: tipo_evento, **dados)
      end

      # Cancela o último evento emitido para a NF-e recebida.
      #
      # @param chave [String] chave de acesso da NF-e
      # @return [FocusNfe::Modelos::Documento]
      def cancelar_evento(chave)
        cancelar_evento_em(chave, caminho: "evento")
      end
    end
  end
end
