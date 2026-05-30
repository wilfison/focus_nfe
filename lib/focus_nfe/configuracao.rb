# frozen_string_literal: true

module FocusNfe
  # Guarda as opções de uso da gem: token, ambiente (que resolve a URL base),
  # timeouts, logger, adaptador HTTP e cabeçalhos extras. Serve tanto ao modo
  # global (FocusNfe.configurar) quanto ao Cliente explícito (multi-empresa).
  class Configuracao
    # @return [Hash{Symbol=>String}] ambiente => URL base da API (sem o prefixo /v2)
    URLS_BASE = {
      producao: "https://api.focusnfe.com.br",
      homologacao: "https://homologacao.focusnfe.com.br"
    }.freeze

    AMBIENTE_PADRAO = :homologacao
    TIMEOUT_PADRAO = 30
    OPEN_TIMEOUT_PADRAO = 10

    attr_accessor :token, :ambiente, :timeout, :open_timeout, :logger,
                  :adaptador_http, :cabecalhos

    # @param token [String, nil] token de acesso da API
    # @param ambiente [Symbol] :producao ou :homologacao
    # @param timeout [Integer] timeout de leitura, em segundos
    # @param open_timeout [Integer] timeout de conexão, em segundos
    # @param logger [Logger, nil] logger apenas armazenado nesta fase
    # @param adaptador_http [FocusNfe::HTTP::Adaptador, nil] instância pronta (nil => Conexao cria a default)
    # @param cabecalhos [Hash] cabeçalhos extras enviados em toda requisição
    def initialize(token: nil, ambiente: AMBIENTE_PADRAO, timeout: TIMEOUT_PADRAO,
                   open_timeout: OPEN_TIMEOUT_PADRAO, logger: nil,
                   adaptador_http: nil, cabecalhos: {})
      @token = token
      @ambiente = ambiente
      @timeout = timeout
      @open_timeout = open_timeout
      @logger = logger
      @adaptador_http = adaptador_http
      @cabecalhos = cabecalhos
    end

    # @return [String] URL base correspondente ao ambiente atual
    # @raise [FocusNfe::Erros::ErroDeConfiguracao] se o ambiente for desconhecido
    def url_base
      validar_ambiente!
      URLS_BASE.fetch(ambiente)
    end

    # Valida a configuração, falhando cedo quando inutilizável.
    #
    # @return [self]
    # @raise [FocusNfe::Erros::ErroDeConfiguracao] token ausente/vazio ou ambiente inválido
    def validar!
      raise Erros::ErroDeConfiguracao, "token é obrigatório" if token.to_s.strip.empty?

      validar_ambiente!
      self
    end

    private

    # @raise [FocusNfe::Erros::ErroDeConfiguracao] se o ambiente não for reconhecido
    def validar_ambiente!
      return if URLS_BASE.key?(ambiente)

      raise Erros::ErroDeConfiguracao,
            "ambiente inválido: #{ambiente.inspect} (use :producao ou :homologacao)"
    end
  end
end
