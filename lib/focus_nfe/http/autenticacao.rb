# frozen_string_literal: true

module FocusNfe
  module HTTP
    # Calcula o cabeçalho HTTP Basic exigido pela API: o token entra como
    # usuário e a senha fica vazia ("token:"). O Base64 vem de Array#pack("m0")
    # (core do Ruby, sem `require`), equivalente exato a
    # Base64.strict_encode64 — evitando a lib `base64`, que deixou de ser
    # default gem no Ruby 4.x, e mantendo zero dependências de runtime.
    module Autenticacao
      NOME = "Authorization"

      module_function

      # @param token [String] token de acesso, usado como usuário do Basic Auth
      # @return [Hash{String=>String}] { "Authorization" => "Basic <base64('token:')>" }
      def cabecalho(token)
        { NOME => "Basic #{["#{token}:"].pack("m0")}" }
      end
    end
  end
end
