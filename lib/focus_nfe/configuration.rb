# frozen_string_literal: true

module FocusNfe
  # Guarda as opções de uso da gem: token, ambiente (que resolve a URL base),
  # timeouts, logger, adaptador HTTP e cabeçalhos extras. Serve tanto ao modo
  # global (FocusNfe.configure) quanto ao Client explícito (multi-empresa).
  class Configuration
    # @return [Hash{Symbol=>String}] ambiente => URL base da API (sem o prefixo /v2)
    BASE_URLS = {
      producao: "https://api.focusnfe.com.br",
      homologacao: "https://homologacao.focusnfe.com.br"
    }.freeze

    DEFAULT_ENVIRONMENT = :homologacao
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10

    attr_accessor :token, :environment, :timeout, :open_timeout, :logger,
                  :http_adapter, :headers

    # @param token [String, nil] token de acesso da API
    # @param environment [Symbol] :producao ou :homologacao
    # @param timeout [Integer] timeout de leitura, em segundos
    # @param open_timeout [Integer] timeout de conexão, em segundos
    # @param logger [Logger, nil] logger apenas armazenado nesta fase
    # @param http_adapter [FocusNfe::HTTP::Adapter, nil] instância pronta (nil => Connection cria a default)
    # @param headers [Hash] cabeçalhos extras enviados em toda requisição
    def initialize(token: nil, environment: DEFAULT_ENVIRONMENT, timeout: DEFAULT_TIMEOUT,
                   open_timeout: DEFAULT_OPEN_TIMEOUT, logger: nil,
                   http_adapter: nil, headers: {})
      @token = token
      @environment = environment
      @timeout = timeout
      @open_timeout = open_timeout
      @logger = logger
      @http_adapter = http_adapter
      @headers = headers
    end

    # @return [String] URL base correspondente ao ambiente atual
    # @raise [FocusNfe::Errors::ConfigurationError] se o ambiente for desconhecido
    def base_url
      validate_environment!
      BASE_URLS.fetch(environment)
    end

    # Valida a configuração, falhando cedo quando inutilizável.
    #
    # @return [self]
    # @raise [FocusNfe::Errors::ConfigurationError] token ausente/vazio ou ambiente inválido
    def validate!
      raise Errors::ConfigurationError, "token é obrigatório" if token.to_s.strip.empty?

      validate_environment!
      self
    end

    private

    # @raise [FocusNfe::Errors::ConfigurationError] se o ambiente não for reconhecido
    def validate_environment!
      return if BASE_URLS.key?(environment)

      raise Errors::ConfigurationError,
            "ambiente inválido: #{environment.inspect} (use :producao ou :homologacao)"
    end
  end
end
