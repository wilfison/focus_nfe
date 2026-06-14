# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de prévia/visualização (+POST /<base_previa>+ com o payload
      # no corpo). Gera o PDF apenas para conferência visual — sem valor fiscal e
      # sem emitir o documento. O caminho é declarado por
      # {Base.caminho_base_previa} em cada recurso (ex.: +"nfe/danfe"+), para que
      # outros documentos com prévia o adotem sem alterar o mixin. A validação
      # opt-in reaproveita o schema via {Concerns::Emitivel}.
      module Visualizavel
        # Gera a prévia do documento a partir do payload, devolvendo os bytes do PDF.
        #
        # @param dados [Hash] payload do documento (mesmos campos da emissão)
        # @param validar [Boolean] se +true+, valida +dados+ contra o schema empacotado antes do envio
        # @return [String, nil] bytes crus do PDF da prévia
        # @raise [FocusNfe::Esquemas::ErroDeValidacao] se +validar+ e +dados+ violarem o schema
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def previa(dados:, validar: false)
          validar_dados!(dados) if validar

          connection.post(caminho_base_previa, body: dados).raw_body
        end
      end
    end
  end
end
