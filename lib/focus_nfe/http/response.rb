# frozen_string_literal: true

require "json"

module FocusNfe
  module HTTP
    # Wrapper imutável de uma resposta HTTP da API Focus NFe.
    #
    # Expõe +status+, +headers+ (leitura case-insensitive), +body+ (JSON
    # parseado quando o +Content-Type+ indica JSON, senão a string crua) e
    # +raw_body+ (sempre a string original). O parsing é eager no construtor —
    # a instância é congelada, então não há memoização preguiçosa.
    class Response
      # Conjunto de cabeçalhos com acesso insensível a maiúsculas/minúsculas.
      class Headers
        # @param source [Hash] cabeçalhos recebidos, em qualquer caixa
        def initialize(source)
          @data = source.each_with_object({}) do |(key, value), memo|
            memo[key.to_s.downcase] = value
          end
          @data.freeze
          freeze
        end

        # @param key [String] nome do cabeçalho, em qualquer caixa
        # @return [String, nil] valor do cabeçalho ou +nil+ se ausente
        def [](key)
          @data[key.to_s.downcase]
        end

        # @return [Hash{String => String}] cópia dos cabeçalhos normalizados
        def to_h
          @data.dup
        end
      end

      JSON_TYPE = %r{\bapplication/(?:[\w.+-]+\+)?json\b}i

      attr_reader :status, :headers, :body, :raw_body

      # @param status [Integer] código de status HTTP
      # @param headers [Hash] cabeçalhos da resposta
      # @param body [String, nil] corpo cru recebido
      def initialize(status:, headers: {}, body: nil)
        @status = status
        @headers = Headers.new(headers)
        @raw_body = body
        @body = parse_body
        freeze
      end

      # @return [Boolean] +true+ quando o status está na faixa 2xx
      def success?
        status.between?(200, 299)
      end

      private

      def parse_body
        return raw_body unless json?
        return nil if raw_body.nil? || raw_body.strip.empty?

        JSON.parse(raw_body)
      rescue JSON::ParserError
        raw_body
      end

      def json?
        type = headers["Content-Type"]
        !type.nil? && type.match?(JSON_TYPE)
      end
    end
  end
end
