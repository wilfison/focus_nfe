# frozen_string_literal: true

require "json"
require "uri"

module FocusNfe
  module HTTP
    # Ponto único de transporte: monta a URL com o prefixo +/v2+, injeta os
    # cabeçalhos padrão (JSON, User-Agent, Basic Auth) mais os extras da
    # {Configuracao}, serializa o corpo Hash para JSON e despacha ao adaptador.
    # Devolve a {Resposta} em 2xx e levanta a exceção tipada em não-2xx — assim
    # cada recurso futuro vira uma camada fina sobre esta classe.
    class Conexao
      PREFIXO = "v2"

      # @return [Hash{String=>String}] cabeçalhos enviados em toda requisição
      CABECALHOS_PADRAO = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => "focus_nfe/#{FocusNfe::VERSION}"
      }.freeze

      # @param configuracao [FocusNfe::Configuracao] configuração já validada
      def initialize(configuracao)
        @configuracao = configuracao
      end

      # @!method get(caminho, parametros: {}, corpo: nil, cabecalhos: {})
      # @!method post(caminho, parametros: {}, corpo: nil, cabecalhos: {})
      # @!method put(caminho, parametros: {}, corpo: nil, cabecalhos: {})
      # @!method delete(caminho, parametros: {}, corpo: nil, cabecalhos: {})
      # @param caminho [String] caminho do recurso, sem o prefixo /v2 (ex.: "nfe")
      # @param parametros [Hash] pares convertidos em query string
      # @param corpo [Hash, String, nil] Hash é serializado para JSON; nil não envia corpo
      # @param cabecalhos [Hash] cabeçalhos extras desta chamada
      # @return [FocusNfe::HTTP::Resposta] em respostas 2xx
      # @raise [FocusNfe::Erros::ErroHttp] a exceção tipada correspondente em não-2xx
      %i[get post put delete].each do |verbo|
        define_method(verbo) do |caminho, parametros: {}, corpo: nil, cabecalhos: {}|
          executar(verbo, caminho, parametros: parametros, corpo: corpo, cabecalhos: cabecalhos)
        end
      end

      private

      attr_reader :configuracao

      def executar(verbo, caminho, parametros:, corpo:, cabecalhos:)
        resposta = adaptador.executar(
          verbo,
          montar_url(caminho, parametros),
          cabecalhos: montar_cabecalhos(cabecalhos),
          corpo: serializar(corpo)
        )

        return resposta if resposta.sucesso?

        raise Erros.a_partir_de(resposta)
      end

      def montar_url(caminho, parametros)
        url = "#{configuracao.url_base}/#{PREFIXO}/#{caminho.to_s.delete_prefix("/")}"
        return url if parametros.nil? || parametros.empty?

        "#{url}?#{URI.encode_www_form(parametros)}"
      end

      def montar_cabecalhos(da_chamada)
        CABECALHOS_PADRAO
          .merge(configuracao.cabecalhos)
          .merge(da_chamada)
          .merge(Autenticacao.cabecalho(configuracao.token))
      end

      def serializar(corpo)
        return if corpo.nil?

        corpo.is_a?(String) ? corpo : JSON.generate(corpo)
      end

      def adaptador
        @adaptador ||= configuracao.adaptador_http ||
                       Adaptadores::NetHttp.new(
                         timeout: configuracao.timeout,
                         open_timeout: configuracao.open_timeout
                       )
      end
    end
  end
end
