# frozen_string_literal: true

module FocusNfe
  # Raiz de toda a hierarquia de exceções da gem. Permite ao integrador capturar
  # qualquer falha do `focus_nfe` com um único `rescue FocusNfe::Erro`.
  class Erro < StandardError; end

  # Exceções tipadas: falhas HTTP (por faixa de status), de configuração
  # (client-side) e de conexão (transporte). O mapeamento status → classe e a
  # construção a partir de uma `Resposta` chegam na US-005.
  module Erros
    # Falha HTTP retornada pela API. Carrega o `status`, o `corpo` já parseado
    # (mensagens de erro da API) e a `Resposta` original que originou a exceção.
    class ErroHttp < Erro
      attr_reader :status, :corpo, :resposta

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
  end
end
