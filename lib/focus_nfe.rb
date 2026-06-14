# frozen_string_literal: true

require_relative "focus_nfe/version"
require_relative "focus_nfe/errors"
require_relative "focus_nfe/configuration"
require_relative "focus_nfe/http/authentication"
require_relative "focus_nfe/http/response"
require_relative "focus_nfe/http/adapter"
require_relative "focus_nfe/http/adapters/net_http"
require_relative "focus_nfe/http/logging"
require_relative "focus_nfe/http/connection"
require_relative "focus_nfe/esquemas/catalogo"
require_relative "focus_nfe/client"

# Ponto de entrada da gem e fachada da configuração global (modo de empresa
# única): {configure}/{configuration}/{client}/{reset_configuration!} operam
# sobre uma {Configuration} memoizada no nível do módulo. Para multi-empresa,
# instancie {Client} explicitamente.
#
# Apenas o núcleo (configuração, HTTP, cliente) é carregado no +require+. Os
# recursos de documento, os modelos e a camada de esquemas são registrados via
# +autoload+ e carregados sob demanda — quem só emite um tipo de documento não
# paga o custo de carregar os demais.
module FocusNfe
  # Recebimento de webhooks inbound (parse + autenticação da chamada).
  autoload :Webhook, "focus_nfe/webhook"

  # Modelos de resposta da API (documento fiscal, página de listagem).
  module Modelos
    autoload :Documento, "focus_nfe/modelos/documento"
    autoload :Inutilizacao, "focus_nfe/modelos/inutilizacao"
    autoload :Pagina, "focus_nfe/modelos/pagina"
  end

  # Camada opcional de esquemas: introspecção pública dos campos e validação
  # client-side opt-in. Ver {Esquemas.descrever} e {Validador}.
  module Esquemas
    autoload :Esquema, "focus_nfe/esquemas/esquema"
    autoload :ErroDeValidacao, "focus_nfe/esquemas/esquema"
    autoload :Campo, "focus_nfe/esquemas/campo"
    autoload :Decimal, "focus_nfe/esquemas/decimal"
    autoload :Validador, "focus_nfe/esquemas/validador"
  end

  # Recursos da API, um por tipo de documento ou consulta. Cada um deriva de
  # {Recursos::Base} e compõe seu comportamento com os mixins de {Concerns}.
  module Recursos
    autoload :Base, "focus_nfe/recursos/base"

    # Mixins de comportamento compartilhados pelos recursos (emissão, consulta,
    # cancelamento, listagem, …).
    module Concerns
      autoload :Emitivel, "focus_nfe/recursos/concerns/emitivel"
      autoload :Consultavel, "focus_nfe/recursos/concerns/consultavel"
      autoload :Cancelavel, "focus_nfe/recursos/concerns/cancelavel"
      autoload :Eventavel, "focus_nfe/recursos/concerns/eventavel"
      autoload :Corrigivel, "focus_nfe/recursos/concerns/corrigivel"
      autoload :Inutilizavel, "focus_nfe/recursos/concerns/inutilizavel"
      autoload :Listavel, "focus_nfe/recursos/concerns/listavel"
      autoload :Baixavel, "focus_nfe/recursos/concerns/baixavel"
      autoload :Localizavel, "focus_nfe/recursos/concerns/localizavel"
      autoload :Notificavel, "focus_nfe/recursos/concerns/notificavel"
      autoload :Removivel, "focus_nfe/recursos/concerns/removivel"
      autoload :Visualizavel, "focus_nfe/recursos/concerns/visualizavel"
    end

    autoload :Nfe, "focus_nfe/recursos/nfe"
    autoload :Nfce, "focus_nfe/recursos/nfce"
    autoload :Nfse, "focus_nfe/recursos/nfse"
    autoload :NfseNacional, "focus_nfe/recursos/nfse_nacional"
    autoload :Cte, "focus_nfe/recursos/cte"
    autoload :CteOs, "focus_nfe/recursos/cte_os"
    autoload :Mdfe, "focus_nfe/recursos/mdfe"
    autoload :Nfcom, "focus_nfe/recursos/nfcom"
    autoload :Dce, "focus_nfe/recursos/dce"
    autoload :Nfgas, "focus_nfe/recursos/nfgas"
    autoload :NfesRecebidas, "focus_nfe/recursos/nfes_recebidas"
    autoload :CtesRecebidas, "focus_nfe/recursos/ctes_recebidas"
    autoload :NfsesNacionaisRecebidas, "focus_nfe/recursos/nfses_nacionais_recebidas"
    autoload :Ceps, "focus_nfe/recursos/ceps"
    autoload :Municipios, "focus_nfe/recursos/municipios"
    autoload :Cfops, "focus_nfe/recursos/cfops"
    autoload :Cnaes, "focus_nfe/recursos/cnaes"
    autoload :Ncms, "focus_nfe/recursos/ncms"
    autoload :Cnpjs, "focus_nfe/recursos/cnpjs"
    autoload :Empresas, "focus_nfe/recursos/empresas"
    autoload :Webhooks, "focus_nfe/recursos/webhooks"
    autoload :EmailsBloqueados, "focus_nfe/recursos/emails_bloqueados"
    autoload :Backups, "focus_nfe/recursos/backups"
  end

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
    # @raise [FocusNfe::Errors::ConfigurationError] se a config global não tiver ao menos um token e ambiente válido
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
