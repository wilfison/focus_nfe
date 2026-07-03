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

      # @param codigo_municipio [String] código IBGE do município
      # @param codigo [String] código do tributo municipal
      # @return [Hash] corpo cru da resposta
      def consultar_codigo_tributario(codigo_municipio, codigo)
        sub_consulta(codigo_municipio, "codigos_tributarios_municipio", codigo)
      end

      # @param codigo_municipio [String] código IBGE do município
      # @param codigo [String] código do item na lista de serviço (ex. +"1.06"+)
      # @return [Hash] corpo cru da resposta
      def consultar_item_lista_servico(codigo_municipio, codigo)
        sub_consulta(codigo_municipio, "itens_lista_servico", codigo)
      end

      # @param codigo_municipio [String] código IBGE do município
      # @return [Hash] JSON de exemplo de NFS-e do município
      def consultar_json(codigo_municipio)
        connection.get("#{caminho_referencia(codigo_municipio)}/json").body
      end

      private

      def sub_listagem(codigo_municipio, sufixo, filtros)
        response = connection.get("#{caminho_referencia(codigo_municipio)}/#{sufixo}", params: filtros)
        Modelos::Pagina.from_response(response)
      end

      def sub_consulta(codigo_municipio, sufixo, codigo)
        segmento = URI.encode_www_form_component(codigo)
        connection.get("#{caminho_referencia(codigo_municipio)}/#{sufixo}/#{segmento}").body
      end
    end
  end
end
