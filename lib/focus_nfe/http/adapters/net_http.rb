# frozen_string_literal: true

require "net/http"
require "uri"

module FocusNfe
  module HTTP
    # Implementações concretas de {Adapter}.
    module Adapters
      # Adaptador HTTP padrão, implementado sobre a stdlib (+Net::HTTP+), sem
      # dependências externas. Aplica os timeouts recebidos no construtor, usa TLS
      # para URLs +https+, segue redirecionamentos +302+ de download (sem reenviar
      # +Authorization+) e relança falhas de transporte como {Errors::ConnectionError}.
      class NetHttp < Adapter
        # @return [Integer] número máximo de redirecionamentos 302 seguidos
        MAX_REDIRECTS = 5

        # @return [Hash{Symbol=>Class}] verbo => classe de requisição Net::HTTP
        VERBS = {
          get: Net::HTTP::Get,
          post: Net::HTTP::Post,
          put: Net::HTTP::Put,
          delete: Net::HTTP::Delete
        }.freeze

        # @param timeout [Integer] timeout de leitura, em segundos
        # @param open_timeout [Integer] timeout de conexão, em segundos
        def initialize(timeout: nil, open_timeout: nil)
          super()
          @timeout = timeout
          @open_timeout = open_timeout
        end

        # @param method [Symbol] verbo HTTP (:get, :post, :put, :delete)
        # @param url [String] URL absoluta da requisição
        # @param headers [Hash{String=>String}] cabeçalhos da requisição
        # @param body [String, nil] corpo já serializado, ou nil
        # @return [FocusNfe::HTTP::Response]
        # @raise [FocusNfe::Errors::ConnectionError] falha de transporte ou excesso de redirecionamentos
        def call(method, url, headers: {}, body: nil)
          dispatch(method, URI(url), headers, body, MAX_REDIRECTS)
        end

        private

        def dispatch(method, uri, headers, body, redirects_left)
          raw = transport(method, uri, headers, body)
          location = raw["location"]

          if raw.code.to_i == 302 && location
            raise Errors::ConnectionError, "excedido o limite de redirecionamentos" if redirects_left.zero?

            target = URI.join(uri.to_s, location)
            return dispatch(:get, target, without_authorization(headers), nil, redirects_left - 1)
          end

          build_response(raw)
        end

        def transport(method, uri, headers, body)
          request = build_request(method, uri, headers, body)
          http_for(uri).request(request)
        rescue Timeout::Error, IOError, SystemCallError => e
          raise Errors::ConnectionError, "falha de transporte: #{e.message}"
        end

        def build_request(method, uri, headers, body)
          klass = VERBS.fetch(method) { raise ArgumentError, "verbo HTTP não suportado: #{method.inspect}" }
          request = klass.new(uri)
          headers.each { |name, value| request[name] = value }
          request.body = body unless body.nil?
          request
        end

        def http_for(uri)
          Net::HTTP.new(uri.host.to_s, uri.port).tap do |http|
            http.use_ssl = uri.scheme == "https"
            read_timeout = @timeout
            open_timeout = @open_timeout
            http.read_timeout = read_timeout if read_timeout
            http.open_timeout = open_timeout if open_timeout
          end
        end

        def build_response(raw)
          headers = raw.each_header.to_h { |name, value| [name, value] }
          Response.new(status: raw.code.to_i, headers: headers, body: raw.body)
        end

        def without_authorization(headers)
          headers.reject { |name, _| name.to_s.casecmp?("authorization") }
        end
      end
    end
  end
end
