# frozen_string_literal: true

module FocusNfe
  # Raiz de acesso à API para um par token/ambiente. Cada cliente carrega sua
  # própria {Configuration} e {HTTP::Connection}, permitindo coexistência de
  # várias empresas no mesmo processo sem estado compartilhado. Expõe os
  # recursos da API instanciados preguiçosamente e memoizados.
  class Client
    # @return [FocusNfe::Configuration] configuração validada deste cliente
    attr_reader :configuration

    # @overload initialize(configuration)
    #   @param configuration [FocusNfe::Configuration] configuração já montada
    # @overload initialize(token:, environment:, **options)
    #   @param token [String] token de acesso da API
    #   @param environment [Symbol] :producao ou :homologacao
    #   @param options [Hash] demais opções da {Configuration} (timeout, headers, …)
    # @raise [FocusNfe::Errors::ConfigurationError] se a configuração for inválida
    def initialize(configuration = nil, **)
      @configuration = (configuration || Configuration.new(**)).tap(&:validate!)
    end

    # @return [FocusNfe::HTTP::Connection] conexão memoizada ligada à configuração
    def connection
      @connection ||= HTTP::Connection.new(configuration)
    end

    # @return [FocusNfe::Recursos::Nfe] recurso de NF-e, memoizado
    def nfe
      @nfe ||= Recursos::Nfe.new(connection)
    end
  end
end
