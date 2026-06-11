# frozen_string_literal: true

module FocusNfe
  # Raiz de toda a hierarquia de exceções da gem. Permite ao integrador capturar
  # qualquer falha do `focus_nfe` com um único `rescue FocusNfe::Erro`.
  class Erro < StandardError; end

  # Exceções tipadas: falhas HTTP (por faixa de status), de configuração
  # (client-side) e de conexão (transporte). Reúne também o mapeamento
  # status → classe e a construção da exceção a partir de uma `Resposta`.
  module Erros
    # Falha HTTP retornada pela API, carregando o status, o corpo parseado com
    # as mensagens de erro da API e a {FocusNfe::HTTP::Resposta} original.
    class ErroHttp < Erro
      # @return [Integer, nil] código de status HTTP da resposta
      attr_reader :status

      # @return [Object, nil] corpo parseado com as mensagens de erro da API
      attr_reader :corpo

      # @return [FocusNfe::HTTP::Resposta, nil] resposta original que originou o erro
      attr_reader :resposta

      # @param mensagem [String, nil] mensagem da exceção
      # @param status [Integer, nil] código de status HTTP
      # @param corpo [Object, nil] corpo parseado da resposta
      # @param resposta [FocusNfe::HTTP::Resposta, nil] resposta original
      def initialize(mensagem = nil, status: nil, corpo: nil, resposta: nil)
        @status = status
        @corpo = corpo
        @resposta = resposta
        super(mensagem)
      end
    end

    # 400 — requisição malformada.
    class RequisicaoInvalida < ErroHttp; end

    # 401 — token ausente ou inválido.
    class NaoAutorizado < ErroHttp; end

    # 403 — autenticado, porém sem permissão para o recurso.
    class Proibido < ErroHttp; end

    # 404 — recurso inexistente.
    class NaoEncontrado < ErroHttp; end

    # 409 — conflito de estado (ex.: `ref` já utilizada).
    class Conflito < ErroHttp; end

    # 422 — erro de validação dos campos enviados.
    class ErroDeValidacao < ErroHttp; end

    # 429 — limite de requisições excedido.
    class LimiteDeRequisicoes < ErroHttp; end

    # 5xx — erro interno do servidor da Focus NFe.
    class ErroDoServidor < ErroHttp; end

    # Status não-2xx sem mapeamento específico (ex.: 418, 451).
    class RespostaInesperada < ErroHttp; end

    # Erro client-side de configuração (token ausente, ambiente inválido) —
    # não envolve resposta HTTP.
    class ErroDeConfiguracao < Erro; end

    # Falha de transporte (timeout, conexão recusada, excesso de redirects).
    class ErroDeConexao < Erro; end

    # @return [Hash{Integer=>Class}] status HTTP específico => classe de exceção
    POR_STATUS = {
      400 => RequisicaoInvalida,
      401 => NaoAutorizado,
      403 => Proibido,
      404 => NaoEncontrado,
      409 => Conflito,
      422 => ErroDeValidacao,
      429 => LimiteDeRequisicoes
    }.freeze

    module_function

    # Resolve a classe de exceção correspondente a um status HTTP.
    #
    # @param status [Integer] código de status HTTP não-2xx
    # @return [Class] subclasse de {ErroHttp}; qualquer 5xx vira {ErroDoServidor}
    #   e qualquer status sem mapeamento específico vira {RespostaInesperada}
    def classe_para(status)
      POR_STATUS[status] || (status.between?(500, 599) ? ErroDoServidor : RespostaInesperada)
    end

    # Constrói a exceção tipada já preenchida a partir de uma resposta.
    #
    # @param resposta [FocusNfe::HTTP::Resposta] resposta não-2xx recebida
    # @return [ErroHttp] instância da classe certa com status/corpo/resposta
    def a_partir_de(resposta)
      classe_para(resposta.status).new(
        "requisição falhou com status #{resposta.status}",
        status: resposta.status,
        corpo: resposta.corpo,
        resposta: resposta
      )
    end
  end
end
