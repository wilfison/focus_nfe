# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de Carta de Correção Eletrônica (CC-e): +POST
      # /<base>/<ref>/carta_correcao+ com o texto da correção no corpo. Devolve o
      # {Modelos::Documento} com o estado fiscal da CC-e.
      module Corrigivel
        # @return [Range] faixa de tamanho aceita para o texto da correção
        TAMANHO_CORRECAO = (15..1000)

        # Emite uma Carta de Correção Eletrônica sobre um documento autorizado.
        #
        # @param ref [String] referência do documento
        # @param correcao [String] texto da correção (15 a 1000 caracteres)
        # @param data_evento [String, nil] data/hora do evento em ISO 8601; omitida usa a data atual
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ ou a +correcao+ forem inválidas
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def corrigir(ref, correcao:, data_evento: nil)
          validar_referencia!(ref)
          validar_correcao!(correcao)

          body = { correcao: correcao }
          body[:data_evento] = data_evento if data_evento
          response = connection.post("#{caminho_referencia(ref)}/carta_correcao", body: body)
          Modelos::Documento.from_response(response, ref: ref)
        end

        private

        # @param correcao [String] texto informado
        # @return [void]
        # @raise [ArgumentError] se não for String ou estiver fora de 15..1000 caracteres
        def validar_correcao!(correcao)
          return if correcao.is_a?(String) && TAMANHO_CORRECAO.cover?(correcao.length)

          raise ArgumentError,
                "correção inválida: esperado String com #{TAMANHO_CORRECAO.min} a #{TAMANHO_CORRECAO.max} caracteres"
        end
      end
    end
  end
end
