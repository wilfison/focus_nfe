# frozen_string_literal: true

module FocusNfe
  # Raiz de toda a hierarquia de exceções da gem. Permite ao integrador capturar
  # qualquer falha do `focus_nfe` com um único `rescue FocusNfe::Error`.
  class Error < StandardError; end

  # Exceções tipadas: falhas HTTP (por faixa de status), de configuração
  # (client-side) e de conexão (transporte). Reúne também o mapeamento
  # status → classe e a construção da exceção a partir de uma `Response`.
  module Errors
    # Falha HTTP retornada pela API, carregando o status, o corpo parseado com
    # as mensagens de erro da API e a {FocusNfe::HTTP::Response} original.
    class HttpError < Error
      # @return [Integer, nil] código de status HTTP da resposta
      attr_reader :status

      # @return [Object, nil] corpo parseado com as mensagens de erro da API
      attr_reader :body

      # @return [FocusNfe::HTTP::Response, nil] resposta original que originou o erro
      attr_reader :response

      # @param message [String, nil] mensagem da exceção
      # @param status [Integer, nil] código de status HTTP
      # @param body [Object, nil] corpo parseado da resposta
      # @param response [FocusNfe::HTTP::Response, nil] resposta original
      def initialize(message = nil, status: nil, body: nil, response: nil)
        @status = status
        @body = body
        @response = response
        super(message)
      end
    end

    # 400 — requisição malformada.
    class BadRequest < HttpError; end

    # 401 — token ausente ou inválido.
    class Unauthorized < HttpError; end

    # 403 — autenticado, porém sem permissão para o recurso.
    class Forbidden < HttpError; end

    # 404 — recurso inexistente.
    class NotFound < HttpError; end

    # 409 — conflito de estado (ex.: `ref` já utilizada).
    class Conflict < HttpError; end

    # 422 — erro de validação dos campos enviados.
    class ValidationError < HttpError; end

    # 429 — limite de requisições excedido.
    class RateLimited < HttpError; end

    # 5xx — erro interno do servidor da Focus NFe.
    class ServerError < HttpError; end

    # Status não-2xx sem mapeamento específico (ex.: 418, 451).
    class UnexpectedResponse < HttpError; end

    # Erro client-side de configuração (token ausente, ambiente inválido) —
    # não envolve resposta HTTP.
    class ConfigurationError < Error; end

    # Falha de transporte (timeout, conexão recusada, excesso de redirects).
    class ConnectionError < Error; end

    # @return [Hash{Integer=>Class}] status HTTP específico => classe de exceção
    BY_STATUS = {
      400 => BadRequest,
      401 => Unauthorized,
      403 => Forbidden,
      404 => NotFound,
      409 => Conflict,
      422 => ValidationError,
      429 => RateLimited
    }.freeze

    module_function

    # Resolve a classe de exceção correspondente a um status HTTP.
    #
    # @param status [Integer] código de status HTTP não-2xx
    # @return [Class] subclasse de {HttpError}; qualquer 5xx vira {ServerError}
    #   e qualquer status sem mapeamento específico vira {UnexpectedResponse}
    def class_for(status)
      BY_STATUS[status] || (status.between?(500, 599) ? ServerError : UnexpectedResponse)
    end

    # Constrói a exceção tipada já preenchida a partir de uma resposta.
    #
    # @param response [FocusNfe::HTTP::Response] resposta não-2xx recebida
    # @return [HttpError] instância da classe certa com status/corpo/resposta
    def from_response(response)
      class_for(response.status).new(
        "requisição falhou com status #{response.status}",
        status: response.status,
        body: response.body,
        response: response
      )
    end
  end
end
