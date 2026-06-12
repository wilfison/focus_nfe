# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de NCMs (Nomenclatura Comum do Mercosul). +consultar(codigo)+ busca
    # um NCM; +buscar+ filtra por código/descrição e componentes.
    class Ncms < Base
      include Concerns::Localizavel
      include Concerns::Listavel

      caminho_base "ncms"

      alias buscar listar
    end
  end
end
