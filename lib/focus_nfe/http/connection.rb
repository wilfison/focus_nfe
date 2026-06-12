# frozen_string_literal: true

require "json"
require "uri"

module FocusNfe
  module HTTP
    # Ponto único de transporte: monta a URL com o prefixo +/v2+, injeta os
    # cabeçalhos padrão (JSON, User-Agent, Basic Auth) mais os extras da
    # {Configuration}, serializa o corpo Hash para JSON e despacha ao adaptador.
    # Devolve a {Response} em 2xx e levanta a exceção tipada em não-2xx — assim
    # cada recurso futuro vira uma camada fina sobre esta classe.
    class Connection
      PREFIX = "v2"

      # @return [Hash{String=>String}] cabeçalhos enviados em toda requisição
      DEFAULT_HEADERS = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => "focus_nfe/#{FocusNfe::VERSION}"
      }.freeze

      # @param configuration [FocusNfe::Configuration] configuração já validada
      # @param token [String] token que autentica esta conexão (empresa ou conta)
      def initialize(configuration, token:)
        @configuration = configuration
        @token = token
      end

      # @!method get(path, params: {}, body: nil, headers: {})
      # @!method post(path, params: {}, body: nil, headers: {})
      # @!method put(path, params: {}, body: nil, headers: {})
      # @!method delete(path, params: {}, body: nil, headers: {})
      # @param path [String] caminho do recurso, sem o prefixo /v2 (ex.: "nfe")
      # @param params [Hash] pares convertidos em query string
      # @param body [Hash, String, nil] Hash é serializado para JSON; nil não envia corpo
      # @param headers [Hash] cabeçalhos extras desta chamada
      # @return [FocusNfe::HTTP::Response] em respostas 2xx
      # @raise [FocusNfe::Errors::HttpError] a exceção tipada correspondente em não-2xx
      %i[get post put delete].each do |verb|
        define_method(verb) do |path, params: {}, body: nil, headers: {}|
          execute(verb, path, params: params, body: body, headers: headers)
        end
      end

      private

      attr_reader :configuration, :token

      def execute(verb, path, params:, body:, headers:)
        response = adapter.call(
          verb,
          build_url(path, params),
          headers: build_headers(headers),
          body: serialize(body)
        )

        return response if response.success?

        raise Errors.from_response(response)
      end

      def build_url(path, params)
        url = "#{configuration.base_url}/#{PREFIX}/#{path.to_s.delete_prefix("/")}"
        return url if params.nil? || params.empty?

        "#{url}?#{URI.encode_www_form(params)}"
      end

      def build_headers(call_headers)
        DEFAULT_HEADERS
          .merge(configuration.headers)
          .merge(call_headers)
          .merge(Authentication.header(token))
      end

      def serialize(body)
        return if body.nil?

        body.is_a?(String) ? body : JSON.generate(body)
      end

      def adapter
        @adapter ||= configuration.http_adapter ||
                     Adapters::NetHttp.new(
                       timeout: configuration.timeout,
                       open_timeout: configuration.open_timeout
                     )
      end
    end
  end
end
