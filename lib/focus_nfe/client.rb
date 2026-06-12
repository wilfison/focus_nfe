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

    # @return [FocusNfe::Recursos::Nfce] recurso de NFC-e, memoizado
    def nfce
      @nfce ||= Recursos::Nfce.new(connection)
    end

    # @return [FocusNfe::Recursos::Nfse] recurso de NFS-e, memoizado
    def nfse
      @nfse ||= Recursos::Nfse.new(connection)
    end

    # @return [FocusNfe::Recursos::NfseNacional] recurso de NFS-e nacional, memoizado
    def nfse_nacional
      @nfse_nacional ||= Recursos::NfseNacional.new(connection)
    end

    # @return [FocusNfe::Recursos::Cte] recurso de CT-e, memoizado
    def cte
      @cte ||= Recursos::Cte.new(connection)
    end

    # @return [FocusNfe::Recursos::CteOs] recurso de CT-e OS, memoizado
    def cte_os
      @cte_os ||= Recursos::CteOs.new(connection)
    end

    # @return [FocusNfe::Recursos::Mdfe] recurso de MDF-e, memoizado
    def mdfe
      @mdfe ||= Recursos::Mdfe.new(connection)
    end

    # @return [FocusNfe::Recursos::Nfcom] recurso de NFCom, memoizado
    def nfcom
      @nfcom ||= Recursos::Nfcom.new(connection)
    end

    # @return [FocusNfe::Recursos::Dce] recurso de DC-e, memoizado
    def dce
      @dce ||= Recursos::Dce.new(connection)
    end

    # @return [FocusNfe::Recursos::Nfgas] recurso de NFGas, memoizado
    def nfgas
      @nfgas ||= Recursos::Nfgas.new(connection)
    end
  end
end
