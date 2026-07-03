# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de Carta de Correção Eletrônica (CC-e) do CT-e/CT-e OS: +POST
      # /<base>/<ref>/carta_correcao+ com a correção _por campo_ no corpo — diferente
      # da CC-e de texto livre da NF-e ({Corrigivel}). Devolve o {Modelos::Documento}
      # com o estado fiscal da CC-e.
      module CorrigivelCte
        # Emite uma Carta de Correção Eletrônica corrigindo um campo do documento.
        #
        # São aceitas até 20 correções por documento, cada uma em uma requisição; vale
        # apenas a última correção enviada. Variáveis tributárias, dados de remetente/
        # destinatário e datas de emissão/saída não podem ser corrigidos.
        #
        # @param ref [String] referência do documento
        # @param campo_corrigido [String] nome do campo a corrigir
        # @param valor_corrigido [String] novo valor do campo
        # @param grupo_corrigido [String, nil] grupo que contém o campo (ex.: +"cargas"+)
        # @param numero_item_grupo_corrigido [String, nil] índice do item, quando o campo está numa lista (inicia em 1)
        # @param campo_api [Integer, String, nil] +1+ para nomes de campo da API (padrão), +0+ para tags XML
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+, +campo_corrigido+ ou +valor_corrigido+ forem inválidos
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def corrigir(ref, campo_corrigido:, valor_corrigido:, grupo_corrigido: nil,
                     numero_item_grupo_corrigido: nil, campo_api: nil)
          validar_referencia!(ref)
          validar_campos_correcao!(campo_corrigido, valor_corrigido)

          body = {
            campo_corrigido: campo_corrigido, valor_corrigido: valor_corrigido,
            grupo_corrigido: grupo_corrigido, numero_item_grupo_corrigido: numero_item_grupo_corrigido,
            campo_api: campo_api
          }.compact
          response = connection.post("#{caminho_referencia(ref)}/carta_correcao", body: body)
          Modelos::Documento.from_response(response, ref: ref)
        end

        private

        # @param campo_corrigido [String] campo informado
        # @param valor_corrigido [String] valor informado
        # @return [void]
        # @raise [ArgumentError] se algum deles não for uma String não-vazia
        def validar_campos_correcao!(campo_corrigido, valor_corrigido)
          return if string_preenchida?(campo_corrigido) && string_preenchida?(valor_corrigido)

          raise ArgumentError, "correção inválida: campo_corrigido e valor_corrigido são obrigatórios"
        end

        # @param valor [Object] valor a checar
        # @return [Boolean] true se for uma String com conteúdo não em branco
        def string_preenchida?(valor)
          valor.is_a?(String) && !valor.strip.empty?
        end
      end
    end
  end
end
