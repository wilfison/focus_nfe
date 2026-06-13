# frozen_string_literal: true

module FocusNfe
  module HTTP
    # Registra cada requisição/resposta no logger configurado, redigindo dados
    # sensíveis. Concentra o nil-guard, a redação de cabeçalhos e a formatação,
    # mantendo a {Connection} enxuta.
    #
    # == Contrato do logger plugável
    #
    # O logger pode ser qualquer objeto compatível com o +Logger+ da biblioteca
    # padrão: responde a +debug+, +info+, +warn+ e +error+, cada um aceitando uma
    # mensagem *ou um bloco*. A gem sempre usa a forma com bloco
    # (+logger.info { ... }+), de modo que a mensagem só é construída quando o
    # nível está habilitado. +Logger.new($stdout)+, +Rails.logger+ e
    # +ActiveSupport::Logger+ conformam. Quando o logger é +nil+ (padrão da
    # {Configuration}), o logging fica inteiramente desligado, sem custo.
    #
    # == Dados sensíveis
    #
    # Cabeçalhos em {SENSITIVE_HEADERS} (notadamente +Authorization+) nunca são
    # registrados — seus valores viram {REDACTED}. O corpo da *requisição* (que
    # carrega o payload fiscal com CPF/CNPJ e valores) nunca é logado; o corpo da
    # *resposta* só aparece em erros (status >= 400), truncado a {BODY_MAX}.
    class Logging
      # @return [String] substituto registrado no lugar de valores sensíveis
      REDACTED = "[FILTERED]"

      # @return [Array<String>] nomes de cabeçalho redigidos (comparados em minúsculas)
      SENSITIVE_HEADERS = %w[authorization].freeze

      # @return [Integer] tamanho máximo do corpo de erro registrado
      BODY_MAX = 2_000

      # @param logger [_Logger, nil] logger plugável ou +nil+ para desligar
      def initialize(logger)
        @logger = logger
      end

      # @param verb [Symbol] verbo HTTP da requisição
      # @param url [String] URL absoluta da requisição
      # @param headers [Hash{String=>String}] cabeçalhos enviados (redigidos antes de logar)
      # @return [void]
      def request(verb, url, headers)
        logger = @logger
        return unless logger

        logger.debug { "[focus_nfe] → #{verb.to_s.upcase} #{url} headers=#{redact(headers)}" }
      end

      # @param verb [Symbol] verbo HTTP da requisição
      # @param url [String] URL absoluta da requisição
      # @param status [Integer] código de status HTTP recebido
      # @param elapsed [Float] tempo decorrido, em segundos
      # @param body [String, nil] corpo cru da resposta, logado apenas em erros (status >= 400)
      # @return [void]
      def response(verb, url, status, elapsed, body)
        logger = @logger
        return unless logger

        linha = "[focus_nfe] ← #{status} #{verb.to_s.upcase} #{url} (#{ms(elapsed)}ms)"

        if status >= 400
          logger.warn { "#{linha} body=#{truncate(body)}" }
        else
          logger.info { linha }
        end
      end

      # @param verb [Symbol] verbo HTTP da requisição
      # @param url [String] URL absoluta da requisição
      # @param error [Exception] falha de transporte ocorrida
      # @param elapsed [Float] tempo decorrido até a falha, em segundos
      # @return [void]
      def failure(verb, url, error, elapsed)
        logger = @logger
        return unless logger

        logger.error { "[focus_nfe] ✕ #{verb.to_s.upcase} #{url} #{error.message} (#{ms(elapsed)}ms)" }
      end

      private

      def redact(headers)
        headers.each_with_object({}) do |(name, value), memo|
          memo[name] = SENSITIVE_HEADERS.include?(name.to_s.downcase) ? REDACTED : value
        end
      end

      def truncate(body)
        text = body.to_s
        text.length > BODY_MAX ? "#{text[0, BODY_MAX]}…" : text
      end

      def ms(elapsed)
        (elapsed * 1000).round
      end
    end
  end
end
