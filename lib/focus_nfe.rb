# frozen_string_literal: true

require_relative "focus_nfe/version"
require_relative "focus_nfe/erros"
require_relative "focus_nfe/configuracao"
require_relative "focus_nfe/http/autenticacao"
require_relative "focus_nfe/http/resposta"
require_relative "focus_nfe/http/adaptador"
require_relative "focus_nfe/http/adaptadores/net_http"
require_relative "focus_nfe/http/conexao"
require_relative "focus_nfe/cliente"

# Ponto de entrada da gem e fachada da configuração global (modo de empresa
# única): {configurar}/{configuracao}/{cliente}/{resetar_configuracao!} operam
# sobre uma {Configuracao} memoizada no nível do módulo. Para multi-empresa,
# instancie {Cliente} explicitamente.
module FocusNfe
  class << self
    # Cede a configuração global ao bloco para ajuste, memoizando-a.
    #
    # @yieldparam configuracao [FocusNfe::Configuracao]
    # @return [FocusNfe::Configuracao] a configuração global
    def configurar
      yield(configuracao) if block_given?
      configuracao
    end

    # @return [FocusNfe::Configuracao] a configuração global, criada como default na primeira chamada
    def configuracao
      @configuracao ||= Configuracao.new
    end

    # @return [FocusNfe::Cliente] cliente construído a partir da config global
    # @raise [FocusNfe::Erros::ErroDeConfiguracao] se a config global não tiver token/ambiente válido
    def cliente
      Cliente.new(configuracao)
    end

    # Limpa a configuração global memoizada.
    #
    # @return [void]
    def resetar_configuracao!
      @configuracao = nil
    end
  end
end
