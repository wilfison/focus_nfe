# frozen_string_literal: true

module FocusNfe
  module Recursos
    # Gestão de empresas (CRUD). Disponível apenas em produção na Focus NFe; o
    # certificado vai em base64 nos dados. A simulação (+dry_run+) valida o cadastro
    # sem persistir.
    class Empresas < Base
      include Concerns::Listavel
      include Concerns::Localizavel
      include Concerns::Removivel

      caminho_base "empresas"

      # Cadastra uma empresa.
      #
      # @param dados [Hash] dados da empresa (certificado PFX em base64 quando aplicável)
      # @param dry_run [Boolean] quando +true+, valida sem persistir (+dry_run=1+)
      # @return [Hash] corpo cru da resposta
      def criar(dados:, dry_run: false)
        params = dry_run ? { dry_run: 1 } : {}
        connection.post(caminho_base, params: params, body: dados).body
      end

      # Atualiza uma empresa existente.
      #
      # @param id [String, Integer] identificador da empresa
      # @param dados [Hash] campos a atualizar
      # @return [Hash] corpo cru da resposta
      def atualizar(id, dados:)
        connection.put(caminho_referencia(id), body: dados).body
      end
    end
  end
end
