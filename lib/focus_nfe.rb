# frozen_string_literal: true

require_relative "focus_nfe/version"
require_relative "focus_nfe/errors"
require_relative "focus_nfe/configuration"
require_relative "focus_nfe/http/authentication"
require_relative "focus_nfe/http/response"
require_relative "focus_nfe/http/adapter"
require_relative "focus_nfe/http/adapters/net_http"
require_relative "focus_nfe/http/connection"
require_relative "focus_nfe/modelos/documento"
require_relative "focus_nfe/recursos/base"
require_relative "focus_nfe/recursos/concerns/emitivel"
require_relative "focus_nfe/recursos/concerns/consultavel"
require_relative "focus_nfe/recursos/concerns/cancelavel"
require_relative "focus_nfe/recursos/nfe"
require_relative "focus_nfe/recursos/nfce"
require_relative "focus_nfe/recursos/nfse"
require_relative "focus_nfe/recursos/nfse_nacional"
require_relative "focus_nfe/recursos/cte"
require_relative "focus_nfe/recursos/cte_os"
require_relative "focus_nfe/recursos/mdfe"
require_relative "focus_nfe/recursos/nfcom"
require_relative "focus_nfe/recursos/dce"
require_relative "focus_nfe/recursos/nfgas"
require_relative "focus_nfe/client"

# Ponto de entrada da gem e fachada da configuração global (modo de empresa
# única): {configure}/{configuration}/{client}/{reset_configuration!} operam
# sobre uma {Configuration} memoizada no nível do módulo. Para multi-empresa,
# instancie {Client} explicitamente.
module FocusNfe
  class << self
    # Cede a configuração global ao bloco para ajuste, memoizando-a.
    #
    # @yieldparam configuration [FocusNfe::Configuration]
    # @return [FocusNfe::Configuration] a configuração global
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # @return [FocusNfe::Configuration] a configuração global, criada como default na primeira chamada
    def configuration
      @configuration ||= Configuration.new
    end

    # @return [FocusNfe::Client] cliente construído a partir da config global
    # @raise [FocusNfe::Errors::ConfigurationError] se a config global não tiver token/ambiente válido
    def client
      Client.new(configuration)
    end

    # Limpa a configuração global memoizada.
    #
    # @return [void]
    def reset_configuration!
      @configuration = nil
    end
  end
end
