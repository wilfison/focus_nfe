# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de Conciliação Financeira (ECONF): registro, consulta e
      # cancelamento por número de protocolo num sub-caminho da referência
      # (+/<base>/<ref>/econf+). Devolve o {Modelos::Documento} com o estado do
      # evento. Uso compartilhado por NF-e e NFC-e.
      module Conciliavel
        # Registra um evento de conciliação financeira sobre o documento autorizado.
        #
        # @param ref [String] referência do documento
        # @param detalhes_pagamento [Array<Hash>] pagamentos a conciliar (1 a 100)
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def registrar_econf(ref, detalhes_pagamento:)
          validar_referencia!(ref)

          response = connection.post("#{caminho_referencia(ref)}/econf",
                                     body: { detalhes_pagamento: detalhes_pagamento })
          Modelos::Documento.from_response(response, ref: ref)
        end

        # Consulta um evento de conciliação financeira pelo número de protocolo.
        #
        # @param ref [String] referência do documento
        # @param numero_protocolo [String] protocolo devolvido no registro do ECONF
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def consultar_econf(ref, numero_protocolo)
          validar_referencia!(ref)

          response = connection.get(caminho_econf(ref, numero_protocolo))
          Modelos::Documento.from_response(response, ref: ref)
        end

        # Cancela um evento de conciliação financeira pelo número de protocolo. Havendo
        # mais de um ECONF na mesma nota, cancele do mais antigo ao mais recente.
        #
        # @param ref [String] referência do documento
        # @param numero_protocolo [String] protocolo devolvido no registro do ECONF
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def cancelar_econf(ref, numero_protocolo)
          validar_referencia!(ref)

          response = connection.delete(caminho_econf(ref, numero_protocolo))
          Modelos::Documento.from_response(response, ref: ref)
        end

        private

        # @param ref [String] referência do documento
        # @param numero_protocolo [String] protocolo do ECONF (escapado no caminho)
        # @return [String] caminho do ECONF por protocolo
        def caminho_econf(ref, numero_protocolo)
          "#{caminho_referencia(ref)}/econf/#{URI.encode_www_form_component(numero_protocolo)}"
        end
      end
    end
  end
end
