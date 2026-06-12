# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de CEPs. +consultar(cep)+ devolve o endereço de um CEP; +buscar+
    # filtra endereços por UF/logradouro/localidade/código IBGE.
    class Ceps < Base
      include Concerns::Localizavel
      include Concerns::Listavel

      caminho_base "ceps"

      alias buscar listar
    end
  end
end
