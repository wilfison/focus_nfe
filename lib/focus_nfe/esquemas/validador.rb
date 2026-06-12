# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Validação client-side opt-in de um payload de emissão contra um {Esquema}:
    # confere presença dos campos obrigatórios e tipo/tamanho dos campos escalares
    # de topo. Não recorre em coleções nem valida enums nesta etapa.
    class Validador
      # @param esquema [Esquema] esquema do documento a validar
      def initialize(esquema)
        @esquema = esquema
      end

      # @param dados [Hash] payload de emissão (chaves String ou Symbol)
      # @return [Array<String>] mensagens dos campos inválidos/ausentes (vazio se válido)
      def validar(dados)
        normalizados = normalizar(dados)

        @esquema.campos.each_with_object([]) do |campo, erros|
          erro = erro_para(campo, normalizados)
          erros << erro if erro
        end
      end

      # @param dados [Hash] payload de emissão
      # @return [void]
      # @raise [ErroDeValidacao] se houver qualquer campo inválido/ausente
      def validar!(dados)
        erros = validar(dados)
        raise ErroDeValidacao, erros unless erros.empty?
      end

      private

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
