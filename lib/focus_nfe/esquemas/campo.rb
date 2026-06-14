# frozen_string_literal: true

require "date"

module FocusNfe
  module Esquemas
    # Um campo de um {Esquema} de emissão, derivado das definições de
    # +campos.focusnfe.com.br+. Conhece o nome do campo, sua obrigatoriedade e
    # sabe parsear o tipo fiscal (+String[1-60]+, +Integer[1-9]+, +Decimal[13.2]+,
    # +Date+, +DateTime+, enum, coleção) em restrições aplicáveis a um valor.
    class Campo
      # @return [Regexp] captura base e tamanho de um escalar de comprimento (ex.: +String[1-60]+)
      ESCALAR = /\A(?<base>String|Integer)\[(?<inicio>\d+)(?:-(?<fim>\d+))?\]/

      # @return [Regexp] captura os códigos declarados em um enum (+* +0+: …+ ou +*+0+: …+)
      CODIGO_ENUM = /\*\s*\+([^+]+)\+/

      # @param definicao [Hash] entrada do schema ({ "name", "type", "required", "collection", … })
      def initialize(definicao)
        @definicao = definicao
        parsear_tipo
      end

      # @return [String] nome do campo no payload de emissão
      def nome = @definicao["name"]

      # @return [String, nil] descrição do campo conforme +campos.focusnfe.com.br+
      def descricao = @definicao["description"]

      # @return [String, nil] tipo bruto como documentado (ex.: +"String[1-60]"+)
      def tipo_bruto = @definicao["type"]

      # @return [String, nil] enumeração dos valores aceitos, como documentada
      def enum = @definicao["enum"]

      # @return [Array<String>] códigos aceitos extraídos do {#enum} (vazio se não houver)
      def valores_enum
        @valores_enum ||= enum.to_s.scan(CODIGO_ENUM).flatten
      end

      # @return [Boolean] se o campo declara um conjunto de valores aceitos
      def enum? = !valores_enum.empty?

      # @return [String, nil] tag XML subjacente do campo
      def tag = @definicao["tag"]

      # Representação serializável do campo, para introspecção externa (devs e
      # ferramentas automatizadas). Coleções aninham a descrição dos subcampos em
      # +:colecao+, em profundidade arbitrária; campos escalares têm +:colecao+ nil.
      #
      # @return [Hash] descrição estruturada do campo
      def to_h
        {
          nome: nome, descricao: descricao, tipo: tipo, tipo_bruto: tipo_bruto,
          obrigatorio: obrigatorio?, tamanho_minimo: tamanho_minimo, tamanho_maximo: tamanho_maximo,
          decimal: decimal&.to_h, enum: enum, tag: tag, colecao: esquema_colecao&.descrever
        }
      end

      # @return [Boolean] se o campo é obrigatório na emissão
      def obrigatorio? = @definicao["required"] == true

      # @return [Boolean] se o campo é uma coleção de subitens
      def colecao? = tipo == :colecao

      # @return [Symbol] tipo parseado (+:string+, +:integer+, +:decimal+, +:date+,
      #   +:datetime+, +:enum+, +:colecao+ ou +:desconhecido+)
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

      # @return [Decimal, nil] especificação decimal do campo, ou +nil+ se não for decimal
      attr_reader :decimal

      # Valida um valor contra o tipo/tamanho e o conjunto de enum do campo.
      # Coleções e tipos desconhecidos não restringem nesta etapa.
      #
      # @param valor [Object] valor informado para o campo
      # @return [String, nil] mensagem de erro ou +nil+ se válido
      def validar_valor(valor)
        erro = validar_tipo(valor)
        return erro if erro

        validar_enum(valor) if enum?
      end

      private

      def parsear_tipo
        bruto = @definicao["type"]
        escalar = bruto && ESCALAR.match(bruto)
        return parsear_escalar(escalar) if escalar

        @decimal = Decimal.parsear(bruto)
        return @tipo = :decimal if @decimal

        @tipo = tipo_nao_escalar(bruto)
      end

      def tipo_nao_escalar(bruto)
        return :colecao if @definicao.key?("collection") || bruto.to_s.start_with?("Coleção")
        return @definicao["enum"] ? :enum : :desconhecido if bruto.nil?
        return :datetime if bruto.start_with?("DateTime")
        return :date if bruto.start_with?("Date")

        :desconhecido
      end

      def parsear_escalar(match)
        @tipo = { "String" => :string, "Integer" => :integer }[match[:base].to_s]
        @tamanho_minimo = Integer(match[:inicio])
        @tamanho_maximo = match[:fim] ? Integer(match[:fim]) : @tamanho_minimo
      end

      def validar_tipo(valor)
        case tipo
        when :string then validar_string(valor)
        when :integer then validar_integer(valor)
        when :decimal then validar_decimal(valor)
        when :date then validar_data(valor, Date)
        when :datetime then validar_data(valor, DateTime)
        end
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

      def validar_decimal(valor)
        mensagem = decimal&.validar(valor)
        "#{nome}: #{mensagem}" if mensagem
      end

      def validar_data(valor, classe)
        classe.iso8601(valor.to_s)
        nil
      rescue ArgumentError, TypeError
        "#{nome}: data inválida (esperado ISO 8601)"
      end

      def validar_enum(valor)
        return if valores_enum.include?(valor.to_s)

        "#{nome}: valor #{valor.inspect} fora do conjunto permitido (#{valores_enum.join(", ")})"
      end
    end
  end
end
