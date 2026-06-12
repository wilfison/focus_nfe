# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Base dos recursos da API. Guarda a {HTTP::Connection} e o +caminho_base+
    # declarado por cada recurso, e oferece os utilitários compartilhados pelos
    # mixins de comportamento ({Emitivel}, {Consultavel}, {Cancelavel}, …):
    # montagem do caminho por referência e validação client-side da +ref+.
    class Base
      REFERENCIA = /\A[\w-]+\z/

      class << self
        # Declara (ou lê) o caminho base do recurso, sem o prefixo +/v2+.
        #
        # @param valor [String, nil] caminho a declarar; omitido apenas lê o atual
        # @return [String, nil] caminho base efetivo da classe
        def caminho_base(valor = nil)
          @caminho_base = valor unless valor.nil?
          @caminho_base
        end
      end

      # @param connection [FocusNfe::HTTP::Connection] conexão do cliente
      def initialize(connection)
        @connection = connection
      end

      # @return [String, nil] caminho base declarado pela classe do recurso
      def caminho_base
        self.class.caminho_base
      end

      private

      attr_reader :connection

      # @param ref [String] referência do documento
      # @return [String] caminho do recurso para a referência (ex.: "nfe/pedido-42")
      def caminho_referencia(ref)
        "#{caminho_base}/#{ref}"
      end

      # Valida a +ref+ client-side antes de qualquer requisição, evitando uma ida
      # à API por um erro trivial de formato.
      #
      # @param ref [String] referência informada
      # @return [void]
      # @raise [ArgumentError] se a +ref+ não for alfanumérica (hífen/underscore permitidos)
      def validar_referencia!(ref)
        return if ref.is_a?(String) && ref.match?(REFERENCIA)

        raise ArgumentError, "referência inválida: #{ref.inspect} (esperado alfanumérico, hífen ou underscore)"
      end
    end
  end
end
