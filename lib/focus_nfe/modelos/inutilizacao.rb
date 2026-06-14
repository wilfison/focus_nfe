# frozen_string_literal: true

module FocusNfe
  module Modelos
    # Objeto de valor imutável que representa o resultado de uma inutilização de
    # numeração. Encapsula o corpo (Hash) da resposta — tanto da criação
    # (+POST+) quanto de cada item da consulta (+GET+) — expondo os campos comuns
    # e o predicado de status. Campos não mapeados continuam acessíveis via
    # {#[]}/{#dados}. Diferente de {Documento}, não carrega +ref+: a inutilização
    # é uma operação de coleção, sem referência por documento.
    class Inutilizacao
      # @return [FocusNfe::HTTP::Response, nil] resposta original; +nil+ para itens de uma consulta
      attr_reader :response

      # @return [Hash] corpo cru da resposta (ou do item)
      attr_reader :dados

      # @return [String, nil] status da inutilização na SEFAZ (ex.: +autorizado+)
      def status = dados["status"]

      # @return [String, nil] código de status retornado pela SEFAZ
      def status_sefaz = dados["status_sefaz"]

      # @return [String, nil] mensagem descritiva retornada pela SEFAZ
      def mensagem_sefaz = dados["mensagem_sefaz"]

      # @return [String, nil] protocolo de autorização da SEFAZ (campo +protocolo_sefaz+)
      def protocolo = dados["protocolo_sefaz"]

      # @return [String, nil] série da numeração inutilizada
      def serie = dados["serie"]

      # @return [String, nil] número inicial da faixa inutilizada
      def numero_inicial = dados["numero_inicial"]

      # @return [String, nil] número final da faixa inutilizada
      def numero_final = dados["numero_final"]

      # Constrói uma {Inutilizacao} a partir de uma {HTTP::Response} de criação.
      #
      # @param response [FocusNfe::HTTP::Response] resposta da inutilização
      # @return [FocusNfe::Modelos::Inutilizacao]
      def self.from_response(response)
        new(dados: response.body.is_a?(Hash) ? response.body : {}, response: response)
      end

      # Constrói uma {Inutilizacao} a partir de um item cru de uma consulta.
      #
      # @param item [Hash] item da resposta de consulta
      # @return [FocusNfe::Modelos::Inutilizacao]
      def self.from_item(item)
        new(dados: item.is_a?(Hash) ? item : {})
      end

      # @param dados [Hash] corpo cru da resposta (ou do item)
      # @param response [FocusNfe::HTTP::Response, nil] resposta original, quando houver
      def initialize(dados:, response: nil)
        @dados = dados
        @response = response
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
    end
  end
end
