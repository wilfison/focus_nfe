# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Download do XML de eventos fiscais de um documento
      # (+GET /<base>/<chave>/<evento>.xml+). Devolve os bytes crus (+raw_body+).
      # Opt-in: só recursos que expõem cancelamento e carta de correção — as notas
      # (NF-e) e conhecimentos (CT-e) recebidos.
      module BaixavelEventos
        # @param chave [String] chave de acesso do documento
        # @return [String, nil] XML do último cancelamento
        def download_xml_cancelamento(chave)
          download_xml_evento(chave, evento: "cancelamento")
        end

        # @param chave [String] chave de acesso do documento
        # @return [String, nil] XML da última carta de correção
        def download_xml_carta_correcao(chave)
          download_xml_evento(chave, evento: "carta_correcao")
        end

        private

        # @param chave [String] chave de acesso do documento
        # @param evento [String] sub-caminho do evento (ex.: +cancelamento+)
        # @return [String, nil] XML cru do evento
        def download_xml_evento(chave, evento:)
          connection.get("#{caminho_referencia(chave)}/#{evento}.xml").raw_body
        end
      end
    end
  end
end
