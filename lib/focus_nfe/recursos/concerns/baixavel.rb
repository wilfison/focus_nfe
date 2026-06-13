# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de download (+GET /<base>/<identificador>.<formato>+). Devolve
      # os bytes crus da resposta (+raw_body+); o eventual +302+ para URL pré-assinada
      # (PDFs) é seguido pelo adaptador sem reenviar a autenticação.
      module Baixavel
        # Baixa o documento no formato indicado, devolvendo os bytes crus.
        #
        # @param identificador [String] chave ou referência do documento
        # @param formato [String, Symbol] extensão desejada (+json+, +xml+, +pdf+, +html+)
        # @return [String] corpo cru da resposta (bytes)
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def baixar(identificador, formato:)
          response = connection.get("#{caminho_referencia(identificador)}.#{URI.encode_www_form_component(formato)}")
          response.raw_body
        end

        # @param identificador [String] chave ou referência do documento
        # @return [String] JSON cru do documento
        def baixar_json(identificador)
          baixar(identificador, formato: :json)
        end

        # @param identificador [String] chave ou referência do documento
        # @return [String] XML cru do documento
        def baixar_xml(identificador)
          baixar(identificador, formato: :xml)
        end

        # @param identificador [String] chave ou referência do documento
        # @return [String] PDF (DANFe/DACTe/DANFSe) cru do documento
        def baixar_pdf(identificador)
          baixar(identificador, formato: :pdf)
        end
      end
    end
  end
end
