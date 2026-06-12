# frozen_string_literal: true

module FocusNfe
  # Introspecção pública dos esquemas empacotados: lista os documentos com schema
  # e descreve seus campos como dado serializável, para devs e ferramentas
  # automatizadas — sem token nem conexão.
  module Esquemas
    GLOB_SCHEMAS = "schema_*.json"

    class << self
      # Nomes dos documentos com schema empacotado, ordenados. Inclui os
      # sub-schemas auxiliares (ex.: +"nfe_item"+, +"cte_transporte_aereo"+), pois
      # também são introspectáveis via {descrever}.
      #
      # @return [Array<String>] nomes de documento aceitos por {descrever}
      def disponiveis
        Dir.glob(File.join(Esquema::DIRETORIO, GLOB_SCHEMAS))
           .map { |caminho| File.basename(caminho, ".json").delete_prefix("schema_") }
           .sort
      end

      # Descrição estruturada dos campos de um documento, para devs e ferramentas
      # automatizadas conhecerem nomes, tipos e obrigatoriedade sem token nem
      # conexão. Coleções aninham seus subcampos (ver {Campo#to_h}).
      #
      # @param nome [String] nome do documento (ver {disponiveis})
      # @return [Array<Hash>, nil] descrição de cada campo, ou +nil+ se não houver schema
      def descrever(nome)
        Esquema.carregar(nome)&.descrever
      end
    end
  end
end
