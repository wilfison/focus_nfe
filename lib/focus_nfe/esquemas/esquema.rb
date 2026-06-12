# frozen_string_literal: true

require "json"

module FocusNfe
  # Camada opcional de esquemas: modela os campos de emissão raspados de
  # +campos.focusnfe.com.br+ (empacotados em +data/schemas/*.json+) como dado,
  # habilitando a validação client-side opt-in via +emitir(..., validar: true)+.
  module Esquemas
    # Erro client-side de validação de schema, levantado antes do envio quando o
    # payload não atende ao {Esquema}. Distinto de {Errors::ValidationError} (HTTP
    # 422), pois não envolve resposta da API.
    class ErroDeValidacao < Error
      # @return [Array<String>] mensagens dos campos inválidos/ausentes
      attr_reader :erros

      # @param erros [Array<String>] mensagens de validação acumuladas
      def initialize(erros)
        @erros = erros
        super("validação client-side falhou: #{erros.join("; ")}")
      end
    end

    # Esquema de emissão de um documento fiscal: a coleção de {Campo}s esperados
    # pela API para aquele tipo de documento.
    class Esquema
      DIRETORIO = File.expand_path("../../../data/schemas", __dir__)

      class << self
        # Carrega o schema empacotado de um documento, memoizando por nome.
        #
        # @param nome [String] nome do documento (ex.: +"nfe"+), igual ao +caminho_base+
        # @return [Esquema, nil] o esquema, ou +nil+ se não houver arquivo para o documento
        def carregar(nome)
          return cache[nome] if cache.key?(nome)

          caminho = File.join(DIRETORIO, "schema_#{nome}.json")
          cache[nome] = File.exist?(caminho) ? new(JSON.parse(File.read(caminho))) : nil
        end

        private

        def cache
          @cache ||= {}
        end
      end

      # @return [Array<Campo>] campos definidos pelo esquema
      attr_reader :campos

      # @param definicoes [Array<Hash>] entradas de campo já parseadas do JSON
      def initialize(definicoes)
        @campos = definicoes.map { |definicao| Campo.new(definicao) }
      end
    end
  end
end
