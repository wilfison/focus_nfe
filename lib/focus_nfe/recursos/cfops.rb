# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de CFOPs (Código Fiscal de Operações e Prestações).
    # +consultar(codigo)+ busca um CFOP; +buscar+ filtra por código/descrição.
    class Cfops < Base
      include Concerns::Localizavel
      include Concerns::Listavel

      caminho_base "cfops"

      alias buscar listar
    end
  end
end
