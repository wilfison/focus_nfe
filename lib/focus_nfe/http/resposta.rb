# frozen_string_literal: true

require "json"

module FocusNfe
  module HTTP
    # Wrapper imutável de uma resposta HTTP da API Focus NFe.
    #
    # Expõe +status+, +cabecalhos+ (leitura case-insensitive), +corpo+ (JSON
    # parseado quando o +Content-Type+ indica JSON, senão a string crua) e
    # +corpo_cru+ (sempre a string original). O parsing é eager no construtor —
    # a instância é congelada, então não há memoização preguiçosa.
    class Resposta
      # Conjunto de cabeçalhos com acesso insensível a maiúsculas/minúsculas.
      class Cabecalhos
        # @param origem [Hash] cabeçalhos recebidos, em qualquer caixa
        def initialize(origem)
          @dados = origem.each_with_object({}) do |(chave, valor), memo|
            memo[chave.to_s.downcase] = valor
          end
          @dados.freeze
          freeze
        end

        # @param chave [String] nome do cabeçalho, em qualquer caixa
        # @return [String, nil] valor do cabeçalho ou +nil+ se ausente
        def [](chave)
          @dados[chave.to_s.downcase]
        end

        # @return [Hash{String => String}] cópia dos cabeçalhos normalizados
        def to_h
          @dados.dup
        end
      end

      TIPO_JSON = %r{\bapplication/(?:[\w.+-]+\+)?json\b}i

      attr_reader :status, :cabecalhos, :corpo, :corpo_cru

      # @param status [Integer] código de status HTTP
      # @param cabecalhos [Hash] cabeçalhos da resposta
      # @param corpo [String, nil] corpo cru recebido
      def initialize(status:, cabecalhos: {}, corpo: nil)
        @status = status
        @cabecalhos = Cabecalhos.new(cabecalhos)
        @corpo_cru = corpo
        @corpo = parsear_corpo
        freeze
      end

      # @return [Boolean] +true+ quando o status está na faixa 2xx
      def sucesso?
        status.between?(200, 299)
      end

      private

      def parsear_corpo
        return corpo_cru unless json?
        return nil if corpo_cru.nil? || corpo_cru.strip.empty?

        JSON.parse(corpo_cru)
      rescue JSON::ParserError
        corpo_cru
      end

      def json?
        tipo = cabecalhos["Content-Type"]
        !tipo.nil? && tipo.match?(TIPO_JSON)
      end
    end
  end
end
