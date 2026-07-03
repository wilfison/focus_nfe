# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Nota Fiscal de Serviço eletrônica (NFS-e). Pré-validação
    # síncrona seguida de autorização assíncrona; o cancelamento fica sujeito às
    # regras da prefeitura. Suporta reenvio da nota por e-mail.
    class Nfse < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Notificavel
      include Concerns::Enviavel

      caminho_base "nfse"
    end
  end
end
