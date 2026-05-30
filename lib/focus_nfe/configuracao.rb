# frozen_string_literal: true

module FocusNfe
  # Guarda as opções de uso da gem: token, ambiente (que resolve a URL base),
  # timeouts, logger, adaptador HTTP e cabeçalhos extras. Serve tanto ao modo
  # global (FocusNfe.configurar) quanto ao Cliente explícito (multi-empresa).
  class Configuracao
    # Ambiente -> URL base da API (sem o prefixo /v2, que é da Conexao).
    URLS_BASE = {
      producao: "https://api.focusnfe.com.br",
      homologacao: "https://homologacao.focusnfe.com.br"
    }.freeze

    AMBIENTE_PADRAO = :homologacao
    TIMEOUT_PADRAO = 30
    OPEN_TIMEOUT_PADRAO = 10

    attr_accessor :token, :ambiente, :timeout, :open_timeout, :logger,
                  :adaptador_http, :cabecalhos

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

    # URL base correspondente ao ambiente atual. Levanta ErroDeConfiguracao se o
    # ambiente não for reconhecido.
    def url_base
      validar_ambiente!
      URLS_BASE.fetch(ambiente)
    end

    # Falha cedo quando a configuração é inutilizável: token ausente/vazio ou
    # ambiente desconhecido. Devolve self para permitir encadeamento.
    def validar!
      raise Erros::ErroDeConfiguracao, "token é obrigatório" if token.to_s.strip.empty?

      validar_ambiente!
      self
    end

    private

    def validar_ambiente!
      return if URLS_BASE.key?(ambiente)

      raise Erros::ErroDeConfiguracao,
            "ambiente inválido: #{ambiente.inspect} (use :producao ou :homologacao)"
    end
  end
end
