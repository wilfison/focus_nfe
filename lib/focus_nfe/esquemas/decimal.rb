# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Especificação decimal de um {Campo} (ex.: +Decimal[13.2]+, +Decimal[13.2-4]+):
    # até +inteiros+ dígitos inteiros e de +casas_minimas+ a +casas_maximas+ casas
    # decimais. Sabe validar um valor informado contra esses limites.
    class Decimal
      # @return [Regexp] captura inteiros e a faixa de casas (ex.: +Decimal[13.2-4]+)
      ESPEC = /\ADecimal\[(?<inteiros>\d+)(?:\.(?<casas_min>\d*)(?:-(?<casas_max>\d+))?)?\]/

      # @return [Regexp] decompõe um valor em parte inteira e fracionária
      VALOR = /\A-?(?<inteira>\d+)(?:[.,](?<fracionaria>\d+))?\z/

      # @param bruto [String, nil] tipo bruto do campo
      # @return [Decimal, nil] a especificação parseada, ou +nil+ se +bruto+ não for decimal
      def self.parsear(bruto)
        match = bruto && ESPEC.match(bruto)
        match && new(match)
      end

      # @return [Integer] quantidade máxima de dígitos inteiros
      attr_reader :inteiros

      # @return [Integer] quantidade mínima de casas decimais
      attr_reader :casas_minimas

      # @return [Integer] quantidade máxima de casas decimais
      attr_reader :casas_maximas

      # @param match [MatchData] captura de {ESPEC}
      def initialize(match)
        @inteiros = Integer(match[:inteiros])
        @casas_minimas = match[:casas_min].to_s.empty? ? 0 : Integer(match[:casas_min])
        @casas_maximas = match[:casas_max] ? Integer(match[:casas_max]) : @casas_minimas
      end

      # Valida um valor decimal. Lenient: aceita menos casas que o mínimo (zeros à
      # direita são equivalentes) — rejeita apenas o claramente inválido.
      #
      # @param valor [Object] valor informado
      # @return [String, nil] mensagem de erro (sem o nome do campo) ou +nil+ se válido
      def validar(valor)
        match = VALOR.match(valor.to_s.strip)
        return "valor decimal inválido" unless match

        erro_de_tamanho(match[:inteira].to_s, match[:fracionaria])
      end

      # @return [Hash] descrição serializável da especificação
      def to_h
        { inteiros: inteiros, casas_minimas: casas_minimas, casas_maximas: casas_maximas }
      end

      private

      def erro_de_tamanho(inteira, fracionaria)
        digitos = inteira.sub(/\A0+(?=\d)/, "").length
        casas = fracionaria&.length || 0
        return "#{digitos} dígitos inteiros excedem o máximo de #{inteiros}" if digitos > inteiros

        "#{casas} casas decimais excedem o máximo de #{casas_maximas}" if casas > casas_maximas
      end
    end
  end
end
