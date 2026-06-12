# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de emissão (+POST /<base>?ref=+). Devolve o {Modelos::Documento}
      # com o estado fiscal inicial (em geral assíncrono: +processando_autorizacao+).
      module Emitivel
        # Emite um documento fiscal.
        #
        # @param ref [String] referência única do documento na sua aplicação
        # @param dados [Hash] payload de emissão (campos do schema, validados server-side)
        # @param validar [Boolean] se +true+, valida +dados+ contra o schema empacotado
        #   antes do envio (documentos sem schema próprio são emitidos sem validar)
        # @param opcoes [Hash] parâmetros de query adicionais (ex.: emissão síncrona)
        # @return [FocusNfe::Modelos::Documento]
        # @raise [ArgumentError] se a +ref+ for inválida
        # @raise [FocusNfe::Esquemas::ErroDeValidacao] se +validar+ e +dados+ violarem o schema
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def emitir(ref:, dados:, validar: false, **opcoes)
          validar_referencia!(ref)
          validar_dados!(dados) if validar

          response = connection.post(caminho_base, params: { ref: ref, **opcoes }, body: dados)
          Modelos::Documento.from_response(response, ref: ref)
        end

        private

        # @param dados [Hash] payload de emissão a validar contra o schema
        # @return [void]
        # @raise [FocusNfe::Esquemas::ErroDeValidacao] se houver campo inválido/ausente
        def validar_dados!(dados)
          esquema = Esquemas::Esquema.carregar(caminho_base)
          return unless esquema

          normalizados = dados.transform_keys(&:to_s)
          aninhados = carregar_aninhados(normalizados)
          erros = Esquemas::Validador.new(esquema, aninhados: aninhados).validar(normalizados)
          raise Esquemas::ErroDeValidacao, erros unless erros.empty?
        end

        # @param dados [Hash] payload normalizado (chaves String)
        # @return [Hash{String => FocusNfe::Esquemas::Esquema}] sub-esquemas por chave aninhada
        def carregar_aninhados(dados)
          esquemas_extras(dados).transform_values { |nome| Esquemas::Esquema.carregar(nome) }.compact
        end
      end
    end
  end
end
