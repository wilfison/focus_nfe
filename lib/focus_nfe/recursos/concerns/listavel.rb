# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de listagem (+GET /<base>+). Os filtros viram query string e
      # a resposta — corpo + cabeçalhos de paginação — é encapsulada numa
      # {Modelos::Pagina}.
      module Listavel
        # Lista os registros do recurso, aplicando os filtros como query string.
        #
        # @param filtros [Hash] filtros e paginação aceitos pelo recurso (ex.: +cnpj:+, +versao:+, +offset:+)
        # @return [FocusNfe::Modelos::Pagina]
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def listar(**filtros)
          response = connection.get(caminho_base, params: filtros)
          Modelos::Pagina.from_response(response)
        end
      end
    end
  end
end
