# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Consulta de CNPJ. +consultar(cnpj)+ devolve os dados cadastrais da empresa
    # com o endereço aninhado.
    class Cnpjs < Base
      include Concerns::Localizavel

      caminho_base "cnpjs"
    end
  end
end
