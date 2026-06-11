# frozen_string_literal: true

module FocusNfe
  # Raiz de acesso à API para um par token/ambiente. Cada cliente carrega sua
  # própria {Configuracao} e {HTTP::Conexao}, permitindo coexistência de várias
  # empresas no mesmo processo sem estado compartilhado. Ainda sem acessores de
  # recurso — estes chegam na fase de recursos.
  class Cliente
    # @return [FocusNfe::Configuracao] configuração validada deste cliente
    attr_reader :configuracao

    # @overload initialize(configuracao)
    #   @param configuracao [FocusNfe::Configuracao] configuração já montada
    # @overload initialize(token:, ambiente:, **opcoes)
    #   @param token [String] token de acesso da API
    #   @param ambiente [Symbol] :producao ou :homologacao
    #   @param opcoes [Hash] demais opções da {Configuracao} (timeout, cabecalhos, …)
    # @raise [FocusNfe::Erros::ErroDeConfiguracao] se a configuração for inválida
    def initialize(configuracao = nil, **opcoes)
      @configuracao = (configuracao || Configuracao.new(**opcoes)).tap(&:validar!)
    end

    # @return [FocusNfe::HTTP::Conexao] conexão memoizada ligada à configuração
    def conexao
      @conexao ||= HTTP::Conexao.new(configuracao)
    end
  end
end
