# frozen_string_literal: true

module FocusNfe
  # Guarda as opções de uso da gem: os dois tokens da Focus NFe (+token_empresa+,
  # que identifica a empresa emitente/consultada, e +token_conta+, usado nas
  # consultas auxiliares e na gestão de empresas), o ambiente (que resolve a URL
  # base), timeouts, logger, adaptador HTTP e cabeçalhos extras. Serve tanto ao
  # modo global (FocusNfe.configure) quanto ao Client explícito (multi-empresa).
  class Configuration
    # @return [Hash{Symbol=>String}] ambiente => URL base da API (sem o prefixo /v2)
    BASE_URLS = {
      producao: "https://api.focusnfe.com.br",
      homologacao: "https://homologacao.focusnfe.com.br"
    }.freeze

    # @return [Hash{Symbol=>Symbol}] escopo => atributo de token correspondente
    ESCOPOS_TOKEN = { empresa: :token_empresa, conta: :token_conta }.freeze

    DEFAULT_ENVIRONMENT = :homologacao
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10

    attr_accessor :token_empresa, :token_conta, :environment, :timeout,
                  :open_timeout, :logger, :http_adapter, :headers

    # @param token_empresa [String, nil] token da empresa (emissão/consulta de documentos)
    # @param token_conta [String, nil] token da conta (consultas auxiliares e gestão de empresas)
    # @param environment [Symbol] :producao ou :homologacao
    # @param timeout [Integer] timeout de leitura, em segundos
    # @param open_timeout [Integer] timeout de conexão, em segundos
    # @param logger [Logger, nil] logger apenas armazenado nesta fase
    # @param http_adapter [FocusNfe::HTTP::Adapter, nil] instância pronta (nil => Connection cria a default)
    # @param headers [Hash] cabeçalhos extras enviados em toda requisição
    def initialize(token_empresa: nil, token_conta: nil, environment: DEFAULT_ENVIRONMENT,
                   timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT,
                   logger: nil, http_adapter: nil, headers: {})
      @token_empresa = token_empresa
      @token_conta = token_conta
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

    # @param escopo [Symbol] :empresa ou :conta
    # @return [String, nil] token correspondente ao escopo
    def token_de(escopo)
      public_send(ESCOPOS_TOKEN.fetch(escopo))
    end

    # Valida o ambiente e a presença de ao menos um token, falhando cedo quando a
    # configuração é inutilizável em qualquer escopo.
    #
    # @return [self]
    # @raise [FocusNfe::Errors::ConfigurationError] ambiente inválido ou nenhum token presente
    def validate!
      validate_environment!
      return self if ESCOPOS_TOKEN.keys.any? { |escopo| token_presente?(escopo) }

      raise Errors::ConfigurationError, "informe token_empresa e/ou token_conta"
    end

    # Valida o ambiente e a presença do token de um escopo específico, no momento
    # em que um recurso daquele escopo é efetivamente usado.
    #
    # @param escopo [Symbol] :empresa ou :conta
    # @return [self]
    # @raise [FocusNfe::Errors::ConfigurationError] ambiente inválido ou token do escopo ausente
    def validate_token!(escopo)
      validate_environment!
      return self if token_presente?(escopo)

      raise Errors::ConfigurationError, "#{ESCOPOS_TOKEN.fetch(escopo)} é obrigatório para esta operação"
    end

    private

    # @raise [FocusNfe::Errors::ConfigurationError] se o ambiente não for reconhecido
    def validate_environment!
      return if BASE_URLS.key?(environment)

      raise Errors::ConfigurationError,
            "ambiente inválido: #{environment.inspect} (use :producao ou :homologacao)"
    end

    def token_presente?(escopo)
      !token_de(escopo).to_s.strip.empty?
    end
  end
end
