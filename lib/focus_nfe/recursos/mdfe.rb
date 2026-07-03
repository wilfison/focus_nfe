# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Recurso de Manifesto Eletrônico de Documentos Fiscais (MDF-e). Emissão
    # assíncrona com consulta de estado, cancelamento e eventos próprios:
    # encerramento, inclusão de condutor e inclusão de DF-e.
    class Mdfe < Base
      include Concerns::Emitivel
      include Concerns::Consultavel
      include Concerns::Cancelavel
      include Concerns::Notificavel
      include Concerns::Eventavel

      caminho_base "mdfe"

      # @return [Hash{String=>String}] chave +modal_<tipo>+ no payload => nome do sub-esquema
      MODAIS = {
        "modal_rodoviario" => "mdfe_transporte_rodoviario",
        "modal_aereo" => "mdfe_transporte_aereo",
        "modal_aquaviario" => "mdfe_transporte_aquaviario",
        "modal_ferroviario" => "mdfe_transporte_ferroviario"
      }.freeze

      # Encerra o MDF-e ao fim da operação de transporte.
      #
      # @param ref [String] referência do manifesto
      # @param data [String] data do encerramento (ISO 8601)
      # @param sigla_uf [String] UF do município de encerramento
      # @param nome_municipio [String] nome do município de encerramento
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def encerrar(ref, data:, sigla_uf:, nome_municipio:)
        emitir_evento_em(ref, caminho: "encerrar", data: data, sigla_uf: sigla_uf, nome_municipio: nome_municipio)
      end

      # Inclui um condutor no MDF-e autorizado.
      #
      # @param ref [String] referência do manifesto
      # @param nome [String] nome completo do condutor
      # @param cpf [String] CPF do condutor
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def incluir_condutor(ref, nome:, cpf:)
        emitir_evento_em(ref, caminho: "inclusao_condutor", nome: nome, cpf: cpf)
      end

      # Inclui documentos fiscais (DF-e) vinculados ao MDF-e autorizado.
      #
      # @param ref [String] referência do manifesto
      # @param protocolo [String] protocolo de autorização do MDF-e
      # @param codigo_municipio_carregamento [String] código do município de carregamento
      # @param documentos [Array<Hash>] documentos com +chave_nfe+ e +codigo_municipio_descarregamento+
      # @param nome_municipio_carregamento [String, nil] nome do município de carregamento
      # @return [FocusNfe::Modelos::Documento]
      # @raise [ArgumentError] se a +ref+ for inválida
      # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
      def incluir_dfe(ref, protocolo:, codigo_municipio_carregamento:, documentos:, nome_municipio_carregamento: nil)
        dados = { protocolo: protocolo, codigo_municipio_carregamento: codigo_municipio_carregamento,
                  documentos: documentos }
        dados[:nome_municipio_carregamento] = nome_municipio_carregamento if nome_municipio_carregamento
        emitir_evento_em(ref, caminho: "inclusao_dfe", **dados)
      end

      private

      # A MDFe não possui campo +modal+: o modal é deduzido pela chave
      # +modal_<tipo>+ presente no payload.
      #
      # @see FocusNfe::Recursos::Base#esquemas_extras
      def esquemas_extras(dados)
        MODAIS.select { |chave, _| dados.key?(chave) }
      end
    end
  end
end
