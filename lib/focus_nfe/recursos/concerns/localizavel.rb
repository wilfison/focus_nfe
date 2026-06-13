# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de consulta por identificador (+GET /<base>/<identificador>+),
      # para recursos de leitura e referência. Devolve o corpo cru da resposta
      # (Hash) — sem validação fiscal de +ref+, pois o identificador é um código,
      # chave ou CNPJ.
      module Localizavel
        # Consulta um registro pelo seu identificador.
        #
        # @param identificador [String] código/chave/CNPJ do registro
        # @return [Hash, Array, nil] corpo cru da resposta
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def consultar(identificador)
          connection.get(caminho_referencia(identificador)).body
        end
      end
    end
  end
end
