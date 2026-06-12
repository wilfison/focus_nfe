# frozen_string_literal: true

module FocusNfe
  module Esquemas
    # Validação condicional do modal dos documentos de transporte (CTe, CTe OS,
    # MDFe). Os campos específicos do modal não vêm no schema principal: chegam
    # aninhados sob a chave +modal_<tipo>+ e devem ser validados contra o
    # sub-esquema empacotado próprio daquele modal.
    #
    # Em CTe e CTe OS o modal é indicado pelo campo +modal+; na MDFe não há
    # discriminador e o modal é deduzido da chave +modal_<tipo>+ presente.
    module Modais
      REGISTRO = {
        "cte" => {
          discriminador: "modal",
          mapa: {
            "01" => %w[modal_rodoviario cte_transporte_rodoviario],
            "02" => %w[modal_aereo cte_transporte_aereo],
            "03" => %w[modal_aquaviario cte_transporte_aquaviario],
            "04" => %w[modal_ferroviario cte_transporte_ferroviario],
            "05" => %w[modal_dutoviario cte_transporte_dutoviario],
            "06" => %w[modal_multimodal cte_transporte_multimodal]
          }
        },
        "cte_os" => {
          discriminador: "modal",
          mapa: {
            "01" => %w[modal_rodoviario cte_os_transporte_rodoviario]
          }
        },
        "mdfe" => {
          discriminador: nil,
          mapa: {
            "01" => %w[modal_rodoviario mdfe_transporte_rodoviario],
            "02" => %w[modal_aereo mdfe_transporte_aereo],
            "03" => %w[modal_aquaviario mdfe_transporte_aquaviario],
            "04" => %w[modal_ferroviario mdfe_transporte_ferroviario]
          }
        }
      }.freeze

      class << self
        # Valida o modal aninhado de um documento de transporte.
        #
        # @param documento [String] nome do documento (ex.: +"cte"+), igual ao +caminho_base+
        # @param dados [Hash] payload de emissão (chaves String ou Symbol)
        # @return [Array<String>] mensagens dos campos inválidos/ausentes do modal (vazio se válido
        #   ou se o documento não possui modal condicional)
        def validar(documento, dados)
          config = REGISTRO[documento.to_s]
          return [] unless config

          normalizados = dados.transform_keys(&:to_s)

          modais_ativos(config, normalizados).flat_map do |chave, nome_esquema|
            validar_modal(chave, nome_esquema, normalizados)
          end
        end

        private

        def modais_ativos(config, dados)
          return [config[:mapa][dados[config[:discriminador]].to_s]].compact if config[:discriminador]

          config[:mapa].values.select { |chave, _| dados.key?(chave) }
        end

        def validar_modal(chave, nome_esquema, dados)
          esquema = Esquema.carregar(nome_esquema)
          return [] unless esquema

          objeto = dados[chave]
          return ["#{chave}: campo obrigatório ausente"] if objeto.nil?
          return ["#{chave}: deve ser um objeto"] unless objeto.is_a?(Hash)

          Validador.new(esquema).validar(objeto).map { |erro| "#{chave}.#{erro}" }
        end
      end
    end
  end
end
