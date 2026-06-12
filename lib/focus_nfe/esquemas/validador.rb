# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Validação client-side opt-in de um payload de emissão contra um {Esquema}:
    # confere presença dos campos obrigatórios e tipo/tamanho dos campos escalares.
    # Recorre em coleções: para cada item do Array valida seus subcampos contra o
    # sub-esquema da coleção, em profundidade arbitrária, prefixando os erros com o
    # caminho — a posição do item é base 1 (ex.: +itens[1].descricao+,
    # +itens[1].adicoes[3].numero+). Enums,
    # datas e decimais não são restringidos nesta etapa.
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
        esquema.campos.flat_map { |campo| erros_para(campo, dados) }
      end

      def validar_aninhados(dados)
        @aninhados.flat_map do |chave, esquema|
          objeto = dados[chave]
          next ["#{chave}: campo obrigatório ausente"] if objeto.nil?
          next ["#{chave}: deve ser um objeto"] unless objeto.is_a?(Hash)

          validar_campos(esquema, normalizar(objeto)).map { |erro| "#{chave}.#{erro}" }
        end
      end

      def erros_para(campo, dados)
        ausente = !dados.key?(campo.nome) || dados[campo.nome].nil?

        return ["#{campo.nome}: campo obrigatório ausente"] if campo.obrigatorio? && ausente
        return [] if ausente
        return validar_colecao(campo, dados[campo.nome]) if campo.colecao?

        erro = campo.validar_valor(dados[campo.nome])
        erro ? [erro] : []
      end

      def validar_colecao(campo, valor)
        return ["#{campo.nome}: deve ser uma coleção"] unless valor.is_a?(Array)

        sub = campo.esquema_colecao
        return [] unless sub

        valor.each_with_index.flat_map do |item, indice|
          prefixo = "#{campo.nome}[#{indice + 1}]"
          next ["#{prefixo}: deve ser um objeto"] unless item.is_a?(Hash)

          validar_campos(sub, normalizar(item)).map { |erro| "#{prefixo}.#{erro}" }
        end
      end

      def normalizar(dados)
        dados.transform_keys(&:to_s)
      end
    end
  end
end
