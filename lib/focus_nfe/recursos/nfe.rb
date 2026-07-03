# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal eletrônica (NF-e). Emissão assíncrona com consulta
    # de estado, cancelamento, Carta de Correção Eletrônica (CC-e), inutilização
    # de numeração, prévia da DANFe, envio por e-mail e importação a partir do XML.
    class Nfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Corrigivel
      include Concerns::Inutilizavel
      include Concerns::Visualizavel
      include Concerns::Notificavel
      include Concerns::Enviavel
      include Concerns::Eventavel
      include Concerns::Conciliavel

      caminho_base "nfe"
      caminho_base_previa "nfe/danfe"

      # Importa uma NF-e a partir do seu XML autorizado.
      #
      # @param xml [String] XML da NF-e (enviado como +application/xml+)
      # @param ref [String, nil] referência a atribuir; omitida usa a chave da nota
      # @return [FocusNfe::Modelos::Documento]
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def importar(xml, ref: nil)
        params = ref ? { ref: ref } : {}
        response = connection.post("#{caminho_base}/importacao",
                                   params: params, body: xml,
                                   headers: { "Content-Type" => "application/xml" })
        Modelos::Documento.from_response(response, ref: ref)
      end

      # Emite um evento genérico sobre a NF-e (+POST /nfe/:ref/evento+).
      #
      # @param ref [String] referência da nota
      # @param tipo_evento [String] tipo do evento suportado pela API
      # @param dados [Hash] campos adicionais específicos do evento
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def emitir_evento(ref, tipo_evento:, **dados)
        emitir_evento_em(ref, caminho: "evento", tipo_evento: tipo_evento, **dados)
      end

      # Cancela um evento da NF-e (+DELETE /nfe/:ref/evento+ com +tipo_evento+ no corpo).
      #
      # @param ref [String] referência da nota
      # @param tipo_evento [String] tipo do evento a cancelar
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def cancelar_evento(ref, tipo_evento:)
        cancelar_evento_em(ref, caminho: "evento", tipo_evento: tipo_evento)
      end

      # Registra o Ator Interessado da NF-e (+POST /nfe/:ref/ator_interessado+),
      # autorizando um terceiro a acessar o XML. Informe +cpf+ ou +cnpj+.
      #
      # @param ref [String] referência da nota
      # @param permite_autorizacao_terceiros [Boolean] libera o acesso ao terceiro
      # @param cpf [String, nil] CPF do ator interessado
      # @param cnpj [String, nil] CNPJ do ator interessado
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def registrar_ator_interessado(ref, permite_autorizacao_terceiros:, cpf: nil, cnpj: nil)
        dados = { permite_autorizacao_terceiros: permite_autorizacao_terceiros }
        dados[:cpf] = cpf if cpf
        dados[:cnpj] = cnpj if cnpj
        emitir_evento_em(ref, caminho: "ator_interessado", **dados)
      end

      # Registra o evento de Insucesso na Entrega (+POST /nfe/:ref/insucesso_entrega+).
      # Quando +motivo_insucesso+ for 4, a API exige +justificativa_insucesso+.
      #
      # @param ref [String] referência da nota
      # @param data_tentativa_entrega [String] data/hora da tentativa (ISO 8601)
      # @param motivo_insucesso [Integer] código do motivo (1 a 4)
      # @param hash_tentativa_entrega [String] hash SHA-1 em Base64 da tentativa
      # @param dados [Hash] campos opcionais (+numero_tentativas+, +justificativa_insucesso+, …)
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def registrar_insucesso_entrega(ref, data_tentativa_entrega:, motivo_insucesso:, hash_tentativa_entrega:, **dados)
        emitir_evento_em(ref, caminho: "insucesso_entrega",
                              data_tentativa_entrega: data_tentativa_entrega,
                              motivo_insucesso: motivo_insucesso,
                              hash_tentativa_entrega: hash_tentativa_entrega, **dados)
      end

      # Cancela o evento de Insucesso na Entrega (+DELETE /nfe/:ref/insucesso_entrega+).
      #
      # @param ref [String] referência da nota
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def cancelar_insucesso_entrega(ref)
        cancelar_evento_em(ref, caminho: "insucesso_entrega")
      end
    end
  end
end
