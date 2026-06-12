# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de municípios e seus sub-recursos de NFS-e (códigos tributários e
    # itens da lista de serviço). +consultar(codigo)+ usa o código IBGE.
    class Municipios < Base
      include Concerns::Localizavel
      include Concerns::Listavel

      caminho_base "municipios"

      # @param codigo_municipio [String] código IBGE do município
      # @param filtros [Hash] filtros/paginação (+codigo:+, +descricao:+, +offset:+, +limit:+)
      # @return [FocusNfe::Modelos::Pagina]
      def listar_codigos_tributarios(codigo_municipio, **filtros)
        sub_listagem(codigo_municipio, "codigos_tributarios_municipio", filtros)
      end

      # @param codigo_municipio [String] código IBGE do município
      # @param filtros [Hash] filtros/paginação (+codigo:+, +descricao:+, +offset:+, +limit:+)
      # @return [FocusNfe::Modelos::Pagina]
      def listar_itens_lista_servico(codigo_municipio, **filtros)
        sub_listagem(codigo_municipio, "itens_lista_servico", filtros)
      end

      private

      def sub_listagem(codigo_municipio, sufixo, filtros)
        response = connection.get("#{caminho_referencia(codigo_municipio)}/#{sufixo}", params: filtros)
        Modelos::Pagina.from_response(response)
      end
    end
  end
end
