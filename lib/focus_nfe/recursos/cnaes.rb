# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de códigos CNAE. +consultar(codigo)+ busca um CNAE; +buscar+ filtra
    # por código/descrição. O caminho da API é +codigos_cnae+.
    class Cnaes < Base
      include Concerns::Localizavel
      include Concerns::Listavel

      caminho_base "codigos_cnae"

      alias buscar listar
    end
  end
end
