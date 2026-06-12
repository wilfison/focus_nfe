# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de NFS-e padrão nacional (DPS). Emissão assíncrona com consulta de
    # estado e cancelamento.
    class NfseNacional < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel

      caminho_base "nfse_nacional"
    end
  end
end
