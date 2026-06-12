# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de backups mensais de XML/DANFE por CNPJ. O recurso responde em
    # +GET /backups/{cnpj}.json+ com as URLs dos pacotes ZIP por mês.
    class Backups < Base
      caminho_base "backups"

      # @param cnpj [String] CNPJ da empresa (14 dígitos)
      # @return [Array<Hash>] lista de backups mensais (+mes+, +danfes+, +xmls+)
      def consultar(cnpj)
        connection.get("#{caminho_referencia(cnpj)}.json").body
      end
    end
  end
end
