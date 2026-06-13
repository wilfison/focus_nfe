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
      # @return [String] diretório dos schemas empacotados (+data/schemas/+)
      DIRETORIO = File.expand_path("../../../data/schemas", __dir__.to_s)

      # @return [Regexp] nomes de schema aceitos (alfanumérico, hífen, underscore)
      NOME_VALIDO = /\A[\w-]+\z/

      class << self
        # Carrega o schema empacotado de um documento, memoizando por nome. Nomes
        # fora do padrão alfanumérico são rejeitados (devolve +nil+) antes de tocar
        # o filesystem, evitando travessia de caminho via +nome+ e não poluindo o
        # cache com entradas arbitrárias.
        #
        # @param nome [String] nome do documento (ex.: +"nfe"+), igual ao +caminho_base+
        # @return [Esquema, nil] o esquema, ou +nil+ se o nome for inválido ou não houver arquivo
        def carregar(nome)
          return cache[nome] if cache.key?(nome)
          return nil unless nome.to_s.match?(NOME_VALIDO)

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

      # Descrição serializável do esquema: um Hash por campo, na ordem do schema.
      #
      # @return [Array<Hash>] descrição estruturada de cada {Campo}
      def descrever
        campos.map(&:to_h)
      end
    end
  end
end
