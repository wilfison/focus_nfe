# frozen_string_literal: true

require "net/http"
require "uri"

module FocusNfe
  module HTTP
    module Adaptadores
      # Adaptador HTTP padrão, implementado sobre a stdlib (+Net::HTTP+), sem
      # dependências externas. Aplica os timeouts recebidos no construtor, usa TLS
      # para URLs +https+, segue redirecionamentos +302+ de download (sem reenviar
      # +Authorization+) e relança falhas de transporte como {Erros::ErroDeConexao}.
      class NetHttp < Adaptador
        # @return [Integer] número máximo de redirecionamentos 302 seguidos
        MAX_REDIRECIONAMENTOS = 5

        # @return [Hash{Symbol=>Class}] verbo => classe de requisição Net::HTTP
        VERBOS = {
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

        # @param metodo [Symbol] verbo HTTP (:get, :post, :put, :delete)
        # @param url [String] URL absoluta da requisição
        # @param cabecalhos [Hash{String=>String}] cabeçalhos da requisição
        # @param corpo [String, nil] corpo já serializado, ou nil
        # @return [FocusNfe::HTTP::Resposta]
        # @raise [FocusNfe::Erros::ErroDeConexao] falha de transporte ou excesso de redirecionamentos
        def executar(metodo, url, cabecalhos: {}, corpo: nil)
          despachar(metodo, URI(url), cabecalhos, corpo, MAX_REDIRECIONAMENTOS)
        end

        private

        def despachar(metodo, uri, cabecalhos, corpo, saltos_restantes)
          bruta = transportar(metodo, uri, cabecalhos, corpo)

          if bruta.code.to_i == 302 && bruta["location"]
            raise Erros::ErroDeConexao, "excedido o limite de redirecionamentos" if saltos_restantes.zero?

            destino = URI.join(uri.to_s, bruta["location"])
            return despachar(:get, destino, sem_autorizacao(cabecalhos), nil, saltos_restantes - 1)
          end

          montar_resposta(bruta)
        end

        def transportar(metodo, uri, cabecalhos, corpo)
          requisicao = construir_requisicao(metodo, uri, cabecalhos, corpo)
          cliente(uri).request(requisicao)
        rescue Timeout::Error, IOError, SystemCallError => e
          raise Erros::ErroDeConexao, "falha de transporte: #{e.message}"
        end

        def construir_requisicao(metodo, uri, cabecalhos, corpo)
          classe = VERBOS.fetch(metodo) { raise ArgumentError, "verbo HTTP não suportado: #{metodo.inspect}" }
          requisicao = classe.new(uri)
          cabecalhos.each { |nome, valor| requisicao[nome] = valor }
          requisicao.body = corpo unless corpo.nil?
          requisicao
        end

        def cliente(uri)
          Net::HTTP.new(uri.host, uri.port).tap do |http|
            http.use_ssl = uri.scheme == "https"
            http.read_timeout = @timeout if @timeout
            http.open_timeout = @open_timeout if @open_timeout
          end
        end

        def montar_resposta(bruta)
          cabecalhos = bruta.each_header.to_h { |nome, valor| [nome, valor] }
          Resposta.new(status: bruta.code.to_i, cabecalhos: cabecalhos, corpo: bruta.body)
        end

        def sem_autorizacao(cabecalhos)
          cabecalhos.reject { |nome, _| nome.to_s.casecmp?("authorization") }
        end
      end
    end
  end
end
