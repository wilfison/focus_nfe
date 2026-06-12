# frozen_string_literal: true

module FocusNfe
  module Modelos
    # Objeto de valor imutável que representa o estado fiscal de um documento.
    # Encapsula o corpo (Hash) das respostas de emissão e consulta — que
    # compartilham o mesmo schema — expondo os campos comuns e predicados de
    # status. Campos não mapeados continuam acessíveis via {#[]}/{#dados}.
    class Documento
      # @return [FocusNfe::HTTP::Response] resposta original que originou o documento
      attr_reader :response

      # @return [String, nil] referência informada na chamada (nem sempre presente no corpo)
      attr_reader :ref

      # @return [Hash] corpo cru da resposta
      attr_reader :dados

      CAMPOS = %i[
        status status_sefaz mensagem_sefaz chave_nfe numero serie
        caminho_xml_nota_fiscal caminho_danfe
      ].freeze

      CAMPOS.each do |campo|
        define_method(campo) { dados[campo.to_s] }
      end

      # Constrói um {Documento} a partir de uma {HTTP::Response}.
      #
      # @param response [FocusNfe::HTTP::Response] resposta de emissão/consulta
      # @param ref [String, nil] referência conhecida pela chamada, injetada quando ausente do corpo
      # @return [FocusNfe::Modelos::Documento]
      def self.from_response(response, ref: nil)
        new(response: response, ref: ref)
      end

      # @param response [FocusNfe::HTTP::Response] resposta de emissão/consulta
      # @param ref [String, nil] referência conhecida pela chamada
      def initialize(response:, ref: nil)
        @response = response
        @dados = response.body.is_a?(Hash) ? response.body : {}
        @ref = ref || @dados["ref"]
        freeze
      end

      # @param chave [String] nome do campo no corpo da resposta
      # @return [Object, nil] valor do campo cru
      def [](chave)
        dados[chave]
      end

      # @return [Boolean]
      def autorizado?
        status == "autorizado"
      end

      # @return [Boolean]
      def cancelado?
        status == "cancelado"
      end

      # @return [Boolean]
      def processando?
        status == "processando_autorizacao"
      end

      # @return [Boolean]
      def erro?
        status.to_s.start_with?("erro")
      end

      # @return [Boolean]
      def denegado?
        status == "denegado"
      end
    end
  end
end
