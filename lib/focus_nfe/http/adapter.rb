# frozen_string_literal: true

module FocusNfe
  # Camada de transporte HTTP: conexão, autenticação, resposta e os adaptadores
  # plugáveis que executam as requisições.
  module HTTP
    # Interface de um cliente HTTP plugável. A {Connection} despacha cada
    # requisição já montada (URL absoluta, cabeçalhos e corpo serializado) para um
    # adaptador, que executa o transporte e devolve uma {Response}.
    #
    # Implementações concretas sobrescrevem +#call+. Timeouts não trafegam por
    # +#call+ — são injetados no construtor do adaptador concreto.
    class Adapter
      # @param method [Symbol] verbo HTTP (:get, :post, :put, :delete)
      # @param url [String] URL absoluta da requisição
      # @param headers [Hash{String=>String}] cabeçalhos da requisição
      # @param body [String, nil] corpo já serializado, ou nil
      # @return [FocusNfe::HTTP::Response]
      # @raise [NotImplementedError] sempre, na interface abstrata
      def call(method, url, headers: {}, body: nil)
        raise NotImplementedError, "#{self.class} deve implementar #call"
      end
    end
  end
end
