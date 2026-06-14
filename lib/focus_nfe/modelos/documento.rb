# frozen_string_literal: true

module FocusNfe
  module Modelos
    # Objeto de valor imutável que representa o estado fiscal de um documento.
    # Encapsula o corpo (Hash) das respostas de emissão e consulta — que
    # compartilham o mesmo schema — expondo os campos comuns e predicados de
    # status. Campos não mapeados continuam acessíveis via {#[]}/{#dados}.
    class Documento
      # @return [FocusNfe::HTTP::Response, nil] resposta original que originou o documento (nil em webhooks inbound)
      attr_reader :response

      # @return [String, nil] referência informada na chamada (nem sempre presente no corpo)
      attr_reader :ref

      # @return [Hash] corpo cru da resposta
      attr_reader :dados

      # @return [String, nil] status do documento na Focus NFe (ex.: +autorizado+)
      def status = dados["status"]

      # @return [String, nil] código de status retornado pela SEFAZ
      def status_sefaz = dados["status_sefaz"]

      # @return [String, nil] mensagem descritiva retornada pela SEFAZ
      def mensagem_sefaz = dados["mensagem_sefaz"]

      # @return [String, nil] chave de acesso do documento autorizado
      def chave_nfe = dados["chave_nfe"]

      # @return [String, nil] número do documento fiscal
      def numero = dados["numero"]

      # @return [String, nil] série do documento fiscal
      def serie = dados["serie"]

      # @return [String, nil] caminho relativo do XML da nota na Focus NFe
      def caminho_xml_nota_fiscal = dados["caminho_xml_nota_fiscal"]

      # @return [String, nil] caminho relativo do PDF (DANFe/DACTe/DANFSe) na Focus NFe
      def caminho_danfe = dados["caminho_danfe"]

      # @return [String, nil] caminho relativo do XML da carta de correção na Focus NFe
      def caminho_xml_carta_correcao = dados["caminho_xml_carta_correcao"]

      # @return [String, nil] caminho relativo do PDF da carta de correção na Focus NFe
      def caminho_pdf_carta_correcao = dados["caminho_pdf_carta_correcao"]

      # @return [String, nil] número sequencial da carta de correção emitida
      def numero_carta_correcao = dados["numero_carta_correcao"]

      # Constrói um {Documento} a partir de uma {HTTP::Response}.
      #
      # @param response [FocusNfe::HTTP::Response] resposta de emissão/consulta
      # @param ref [String, nil] referência conhecida pela chamada, injetada quando ausente do corpo
      # @return [FocusNfe::Modelos::Documento]
      def self.from_response(response, ref: nil)
        new(dados: response.body, ref: ref, response: response)
      end

      # Constrói um {Documento} a partir do corpo já parseado de um webhook
      # inbound — sem {HTTP::Response} associada.
      #
      # @param corpo [Hash] corpo do webhook, com o mesmo schema das respostas
      # @param ref [String, nil] referência conhecida, injetada quando ausente do corpo
      # @return [FocusNfe::Modelos::Documento]
      def self.from_payload(corpo, ref: nil)
        new(dados: corpo, ref: ref)
      end

      # @param dados [Object] corpo da resposta/webhook (usa {} quando não é Hash)
      # @param ref [String, nil] referência conhecida pela chamada
      # @param response [FocusNfe::HTTP::Response, nil] resposta original, quando houver
      def initialize(dados:, ref: nil, response: nil)
        @response = response
        @dados = dados.is_a?(Hash) ? dados : {}
        @ref = ref || @dados["ref"]
        freeze
      end

      # @param chave [String] nome do campo no corpo da resposta
      # @return [Object, nil] valor do campo cru
      def [](chave)
        dados[chave]
      end

      # @return [Boolean]
      def autorizado?
        status == "autorizado"
      end

      # @return [Boolean]
      def cancelado?
        status == "cancelado"
      end

      # @return [Boolean]
      def processando?
        status == "processando_autorizacao"
      end

      # @return [Boolean]
      def erro?
        status.to_s.start_with?("erro")
      end

      # @return [Boolean]
      def denegado?
        status == "denegado"
      end
    end
  end
end
