# frozen_string_literal: true

module FocusNfe
  module Modelos
    # Coleção paginada de uma resposta de listagem. Encapsula o corpo (Array de
    # Hashes crus) e os cabeçalhos de sincronização incremental, expondo os itens
    # de forma enumerável. Itens permanecem como Hash — modelos leves nas
    # auxiliares/recebidas, conforme a arquitetura.
    class Pagina
      include Enumerable

      # @return [FocusNfe::HTTP::Response] resposta original da listagem
      attr_reader :response

      # @return [Array] itens da página (corpo cru da resposta)
      attr_reader :itens

      # @return [Integer, nil] total de registros disponíveis (cabeçalho +X-Total-Count+)
      attr_reader :total

      # @return [Integer, nil] maior versão presente (cabeçalho +X-Max-Version+), para sincronização incremental
      attr_reader :versao_maxima

      # Constrói uma {Pagina} a partir de uma {HTTP::Response} de listagem.
      #
      # @param response [FocusNfe::HTTP::Response] resposta de uma listagem
      # @return [FocusNfe::Modelos::Pagina]
      def self.from_response(response)
        new(response: response)
      end

      # @param response [FocusNfe::HTTP::Response] resposta de uma listagem
      def initialize(response:)
        @response = response
        @itens = response.body.is_a?(Array) ? response.body : []
        @total = response.headers["X-Total-Count"]&.to_i
        @versao_maxima = response.headers["X-Max-Version"]&.to_i
        freeze
      end

      # Itera os itens da página.
      #
      # @yieldparam item [Object] item cru da listagem
      # @return [self, Enumerator] +self+ quando há bloco; um Enumerator caso contrário
      def each(&)
        return to_enum(:each) unless block_given?

        itens.each(&)
        self
      end
      alias cada each
    end
  end
end
