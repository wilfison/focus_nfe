# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Um campo de um {Esquema} de emissão, derivado das definições de
    # +campos.focusnfe.com.br+. Conhece o nome do campo, sua obrigatoriedade e
    # sabe parsear o tipo fiscal (+String[1-60]+, +Integer[1-9]+, +Decimal[13.2]+,
    # +DateTime+, enum, coleção) em restrições de tipo/tamanho aplicáveis a um valor.
    class Campo
      ESCALAR = /\A(?<base>String|Integer|Decimal)\[(?<inicio>\d+)(?:[-.](?<fim>\d+))?\]/

      # @param definicao [Hash] entrada do schema ({ "name", "type", "required", "collection", … })
      def initialize(definicao)
        @definicao = definicao
        parsear_tipo
      end

      # @return [String] nome do campo no payload de emissão
      def nome
        @definicao["name"]
      end

      # @return [String, nil] descrição do campo conforme +campos.focusnfe.com.br+
      def descricao
        @definicao["description"]
      end

      # @return [String, nil] tipo bruto como documentado (ex.: +"String[1-60]"+)
      def tipo_bruto
        @definicao["type"]
      end

      # @return [String, nil] enumeração dos valores aceitos, quando houver
      def enum
        @definicao["enum"]
      end

      # @return [String, nil] tag XML subjacente do campo
      def tag
        @definicao["tag"]
      end

      # Representação serializável do campo, para introspecção externa (devs e
      # ferramentas automatizadas). Coleções aninham a descrição dos subcampos em
      # +:colecao+, em profundidade arbitrária; campos escalares têm +:colecao+ nil.
      #
      # @return [Hash] descrição estruturada do campo
      def to_h
        {
          nome: nome, descricao: descricao, tipo: tipo, tipo_bruto: tipo_bruto,
          obrigatorio: obrigatorio?, tamanho_minimo: tamanho_minimo, tamanho_maximo: tamanho_maximo,
          enum: enum, tag: tag, colecao: esquema_colecao&.descrever
        }
      end

      # @return [Boolean] se o campo é obrigatório na emissão
      def obrigatorio?
        @definicao["required"] == true
      end

      # @return [Boolean] se o campo é uma coleção de subitens
      def colecao?
        tipo == :colecao
      end

      # @return [Symbol] tipo parseado (+:string+, +:integer+, +:decimal+, +:datetime+,
      #   +:enum+, +:colecao+ ou +:desconhecido+)
      attr_reader :tipo

      # @return [Esquema, nil] esquema dos subcampos da coleção, ou +nil+ se o campo
      #   não for coleção ou não declarar +object_attributes+
      def esquema_colecao
        return unless colecao?

        @esquema_colecao ||= (atributos = @definicao.dig("collection", "object_attributes")) && Esquema.new(atributos)
      end

      # @return [Integer, nil] tamanho/quantidade de dígitos mínimo (escalares)
      attr_reader :tamanho_minimo

      # @return [Integer, nil] tamanho/quantidade de dígitos máximo (escalares)
      attr_reader :tamanho_maximo

      # Valida um valor escalar contra o tipo/tamanho do campo. Enums, datas,
      # coleções e tipos desconhecidos não restringem nesta etapa.
      #
      # @param valor [Object] valor informado para o campo
      # @return [String, nil] mensagem de erro ou +nil+ se válido
      def validar_valor(valor)
        case tipo
        when :string then validar_string(valor)
        when :integer then validar_integer(valor)
        end
      end

      private

      def parsear_tipo
        bruto = @definicao["type"]
        match = bruto && ESCALAR.match(bruto)

        match ? parsear_escalar(match) : (@tipo = tipo_nao_escalar(bruto))
      end

      def tipo_nao_escalar(bruto)
        return :colecao if @definicao.key?("collection") || bruto.to_s.start_with?("Coleção")
        return @definicao["enum"] ? :enum : :desconhecido if bruto.nil?
        return :datetime if bruto.start_with?("DateTime")

        :desconhecido
      end

      def parsear_escalar(match)
        @tipo = { "String" => :string, "Integer" => :integer, "Decimal" => :decimal }[match[:base]]
        @tamanho_minimo = Integer(match[:inicio])
        @tamanho_maximo = match[:fim] ? Integer(match[:fim]) : @tamanho_minimo
      end

      def validar_string(valor)
        comprimento = valor.to_s.length
        return if comprimento.between?(tamanho_minimo, tamanho_maximo)

        "#{nome}: tamanho #{comprimento} fora do intervalo #{tamanho_minimo}-#{tamanho_maximo}"
      end

      def validar_integer(valor)
        digitos = valor.to_s
        return "#{nome}: deve conter apenas dígitos" unless digitos.match?(/\A\d+\z/)
        return if digitos.length.between?(tamanho_minimo, tamanho_maximo)

        "#{nome}: #{digitos.length} dígitos fora do intervalo #{tamanho_minimo}-#{tamanho_maximo}"
      end
    end
  end
end
