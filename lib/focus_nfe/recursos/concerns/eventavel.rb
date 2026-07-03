# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Transporte de eventos fiscais sobre um documento (+POST+/+DELETE+ num
      # sub-caminho da referência). Cada recurso expõe seus eventos por cima
      # destes helpers — o MDF-e com nomes próprios (+encerrar+, +incluir_condutor+,
      # +incluir_dfe+) e as notas recebidas com +emitir_evento+/+cancelar_evento+.
      # Devolve o {Modelos::Documento} com o estado fiscal resultante do evento.
      module Eventavel
        private

        # Emite um evento sobre o documento (+POST /<base>/<ref>/<caminho>+).
        #
        # @param ref [String] referência do documento
        # @param caminho [String] sub-caminho do evento (ex.: +encerrar+)
        # @param dados [Hash] campos do corpo do evento
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def emitir_evento_em(ref, caminho:, **dados)
          validar_referencia!(ref)

          response = connection.post("#{caminho_referencia(ref)}/#{caminho}", body: dados)
          Modelos::Documento.from_response(response, ref: ref)
        end

        # Cancela um evento do documento (+DELETE /<base>/<ref>/<caminho>+).
        #
        # @param ref [String] referência do documento
        # @param caminho [String] sub-caminho do evento (ex.: +evento+)
        # @param dados [Hash] campos do corpo do cancelamento; omitidos não enviam corpo
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def cancelar_evento_em(ref, caminho:, **dados)
          validar_referencia!(ref)

          response = connection.delete("#{caminho_referencia(ref)}/#{caminho}", body: dados.empty? ? nil : dados)
          Modelos::Documento.from_response(response, ref: ref)
        end
      end
    end
  end
end
