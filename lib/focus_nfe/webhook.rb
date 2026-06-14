# frozen_string_literal: true

require "json"

module FocusNfe
  # Recebimento de webhooks inbound: quando a Focus NFe chama a URL da aplicação
  # ao mudar o status de um documento. Fachada stateless (sem token, sem HTTP) —
  # apenas transforma o corpo cru recebido e autentica a chamada.
  #
  # @see FocusNfe::Recursos::Webhooks gestão dos gatilhos (lado saída)
  module Webhook
    module_function

    # Converte o corpo cru de um webhook inbound em um {Modelos::Documento}, o
    # mesmo objeto devolvido por emissão/consulta.
    #
    # @param raw_body [String, Hash] corpo recebido (JSON cru ou já parseado)
    # @param ref [String, nil] referência conhecida, injetada quando ausente do corpo
    # @return [FocusNfe::Modelos::Documento]
    # @raise [FocusNfe::Errors::WebhookError] quando o corpo é uma String que não é JSON válido
    def parse(raw_body, ref: nil)
      dados = raw_body.is_a?(String) ? JSON.parse(raw_body) : raw_body
      Modelos::Documento.from_payload(dados, ref: ref)
    rescue JSON::ParserError => e
      raise Errors::WebhookError, "corpo do webhook não é JSON válido: #{e.message}"
    end

    # Verifica se a chamada é autêntica comparando o header recebido com o
    # +authorization+ configurado na criação do gatilho. A comparação é feita em
    # tempo constante para não vazar o segredo por timing.
    #
    # @param headers [#[]] cabeçalhos da requisição recebida (ex.: +request.headers+ do Rails)
    # @param authorization [String] valor esperado, igual ao informado em {Recursos::Webhooks#criar}
    # @param authorization_header [String] nome do header onde a Focus envia o valor
    # @return [Boolean] +true+ somente quando o header existe e bate com o esperado
    def autenticado?(headers:, authorization:, authorization_header:)
      recebido = valor_do_header(headers, authorization_header)
      !recebido.nil? && comparacao_segura?(recebido.to_s, authorization.to_s)
    end

    # @param headers [#[]] cabeçalhos da requisição
    # @param nome [String] nome do header procurado
    # @return [Object, nil] valor do header, com fallback case-insensitive em Hash
    def valor_do_header(headers, nome)
      direto = headers[nome]
      return direto unless direto.nil?
      return nil unless headers.respond_to?(:each)

      alvo = nome.to_s.downcase
      headers.each { |chave, valor| return valor if chave.to_s.downcase == alvo }
      nil
    end

    # @param esquerda [String]
    # @param direita [String]
    # @return [Boolean] comparação de strings resistente a timing attack
    def comparacao_segura?(esquerda, direita)
      return false unless esquerda.bytesize == direita.bytesize

      bytes_direita = direita.bytes
      diferenca = 0
      esquerda.bytes.each_with_index { |byte, i| diferenca |= byte ^ bytes_direita[i].to_i }
      diferenca.zero?
    end

    private_class_method :valor_do_header, :comparacao_segura?
  end
end
