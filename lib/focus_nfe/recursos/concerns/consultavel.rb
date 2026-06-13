# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de consulta (+GET /<base>/<ref>+). Devolve o {Modelos::Documento}
      # com o estado fiscal atual do documento.
      module Consultavel
        # Consulta o estado de um documento já emitido.
        #
        # @param ref [String] referência do documento
        # @param completa [Boolean] quando +true+, pede a resposta completa (+completa=1+)
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def consultar(ref, completa: false)
          validar_referencia!(ref)

          params = completa ? { completa: 1 } : {}
          response = connection.get(caminho_referencia(ref), params: params)
          Modelos::Documento.from_response(response, ref: ref)
        end
      end
    end
  end
end
