# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de exclusão por identificador (+DELETE /<base>/<identificador>+),
      # para recursos de gestão (CRUD).
      module Removivel
        # Exclui um registro pelo seu identificador.
        #
        # @param identificador [String] id do registro
        # @return [Hash, Array, nil] corpo cru da resposta
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def excluir(identificador)
          connection.delete(caminho_referencia(identificador)).body
        end
      end
    end
  end
end
