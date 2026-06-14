# frozen_string_literal: true

module FocusNfe
  module Recursos
    module Concerns
      # Comportamento de inutilização de numeração: criação (+POST
      # /<base>/inutilizacao+, devolvendo um {Modelos::Inutilizacao}) e consulta
      # das já criadas (+GET /<base>/inutilizacoes+, devolvendo uma lista de
      # {Modelos::Inutilizacao}). É uma operação de coleção — sem +ref+ por
      # documento.
      module Inutilizavel
        # @return [String] segmento do caminho de criação (singular)
        CAMINHO_INUTILIZACAO = "inutilizacao"

        # @return [String] segmento do caminho de consulta (plural)
        CAMINHO_INUTILIZACOES = "inutilizacoes"

        # @return [Integer] tamanho mínimo da justificativa exigido pela SEFAZ
        JUSTIFICATIVA_MINIMA = 15

        # Inutiliza uma faixa de numeração não utilizada.
        #
        # @param cnpj [String] CNPJ do emitente
        # @param serie [String, Integer] série da numeração
        # @param numero_inicial [String, Integer] número inicial da faixa
        # @param numero_final [String, Integer] número final da faixa
        # @param justificativa [String] motivo da inutilização (mínimo 15 caracteres)
        # @return [FocusNfe::Modelos::Inutilizacao]
        # @raise [ArgumentError] se a +justificativa+ for inválida
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def inutilizar(cnpj:, serie:, numero_inicial:, numero_final:, justificativa:)
          validar_justificativa!(justificativa)
          validar_faixa!(numero_inicial, numero_final)

          body = { cnpj: cnpj, serie: serie, numero_inicial: numero_inicial,
                   numero_final: numero_final, justificativa: justificativa }
          response = connection.post("#{caminho_base}/#{CAMINHO_INUTILIZACAO}", body: body)
          Modelos::Inutilizacao.from_response(response)
        end

        # Consulta as inutilizações já registradas, aplicando os filtros como query string.
        #
        # @param filtros [Hash] filtros aceitos pela API (ex.: +cnpj:+, +cpf:+, +numero_inicial:+)
        # @return [Array<FocusNfe::Modelos::Inutilizacao>]
        # @raise [FocusNfe::Errors::HttpError] em respostas não-2xx
        def consultar_inutilizacoes(**filtros)
          response = connection.get("#{caminho_base}/#{CAMINHO_INUTILIZACOES}", params: filtros)
          itens = response.body.is_a?(Array) ? response.body : []
          itens.map { |item| Modelos::Inutilizacao.from_item(item) }
        end

        private

        # @param justificativa [String] justificativa informada
        # @return [void]
        # @raise [ArgumentError] se não for String ou tiver menos de 15 caracteres
        def validar_justificativa!(justificativa)
          return if justificativa.is_a?(String) && justificativa.length >= JUSTIFICATIVA_MINIMA

          raise ArgumentError,
                "justificativa inválida: esperado String com ao menos #{JUSTIFICATIVA_MINIMA} caracteres"
        end

        # Valida a faixa de numeração: ambos os números presentes, inteiros, e
        # +numero_inicial+ não maior que +numero_final+ (faixa de um único número
        # é permitida).
        #
        # @param numero_inicial [String, Integer] número inicial informado
        # @param numero_final [String, Integer] número final informado
        # @return [void]
        # @raise [ArgumentError] se algum número for ausente/não inteiro ou se inicial > final
        def validar_faixa!(numero_inicial, numero_final)
          inicial = numero_para_inteiro(numero_inicial)
          final = numero_para_inteiro(numero_final)

          if inicial.nil? || final.nil?
            raise ArgumentError, "numeração inválida: numero_inicial e numero_final devem ser inteiros"
          end

          return if inicial <= final

          raise ArgumentError, "numeração inválida: numero_inicial (#{inicial}) maior que numero_final (#{final})"
        end

        # @param valor [Object] valor informado
        # @return [Integer, nil] o valor como inteiro (base 10) ou +nil+ se não for conversível
        def numero_para_inteiro(valor)
          case valor
          when Integer then valor
          when String then Integer(valor, 10, exception: false)
          end
        end
      end
    end
  end
end
