# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Validação client-side opt-in de um payload de emissão contra um {Esquema}:
    # confere presença dos campos obrigatórios e tipo/tamanho dos campos escalares
    # de topo. Não recorre em coleções nem valida enums nesta etapa.
    #
    # Além do esquema de topo, aceita sub-esquemas +aninhados+ — indexados pela
    # chave do payload que os contém (ex.: +modal_rodoviario+) — para validar
    # objetos aninhados cujo esquema depende de dados de runtime. Os erros do
    # objeto aninhado vêm prefixados pela chave (ex.: +modal_rodoviario.rntrc+).
    class Validador
      # @param esquema [Esquema] esquema dos campos de topo do documento
      # @param aninhados [Hash{String => Esquema}] sub-esquemas por chave aninhada do payload
      def initialize(esquema, aninhados: {})
        @esquema = esquema
        @aninhados = aninhados
      end

      # @param dados [Hash] payload de emissão (chaves String ou Symbol)
      # @return [Array<String>] mensagens dos campos inválidos/ausentes (vazio se válido)
      def validar(dados)
        normalizados = normalizar(dados)

        validar_campos(@esquema, normalizados) + validar_aninhados(normalizados)
      end

      # @param dados [Hash] payload de emissão
      # @return [void]
      # @raise [ErroDeValidacao] se houver qualquer campo inválido/ausente
      def validar!(dados)
        erros = validar(dados)
        raise ErroDeValidacao, erros unless erros.empty?
      end

      private

      def validar_campos(esquema, dados)
        esquema.campos.each_with_object([]) do |campo, erros|
          erro = erro_para(campo, dados)
          erros << erro if erro
        end
      end

      def validar_aninhados(dados)
        @aninhados.flat_map do |chave, esquema|
          objeto = dados[chave]
          next ["#{chave}: campo obrigatório ausente"] if objeto.nil?
          next ["#{chave}: deve ser um objeto"] unless objeto.is_a?(Hash)

          validar_campos(esquema, normalizar(objeto)).map { |erro| "#{chave}.#{erro}" }
        end
      end

      def erro_para(campo, dados)
        ausente = !dados.key?(campo.nome) || dados[campo.nome].nil?

        return "#{campo.nome}: campo obrigatório ausente" if campo.obrigatorio? && ausente
        return if ausente || campo.colecao?

        campo.validar_valor(dados[campo.nome])
      end

      def normalizar(dados)
        dados.transform_keys(&:to_s)
      end
    end
  end
end
