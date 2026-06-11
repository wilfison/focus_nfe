# frozen_string_literal: true

module FocusNfe
  module HTTP
    # Interface de um cliente HTTP plugável. A {Conexao} despacha cada requisição
    # já montada (URL absoluta, cabeçalhos e corpo serializado) para um adaptador,
    # que executa o transporte e devolve uma {Resposta}.
    #
    # Implementações concretas sobrescrevem +#executar+. Timeouts não trafegam por
    # +#executar+ — são injetados no construtor do adaptador concreto.
    class Adaptador
      # @param metodo [Symbol] verbo HTTP (:get, :post, :put, :delete)
      # @param url [String] URL absoluta da requisição
      # @param cabecalhos [Hash{String=>String}] cabeçalhos da requisição
      # @param corpo [String, nil] corpo já serializado, ou nil
      # @return [FocusNfe::HTTP::Resposta]
      # @raise [NotImplementedError] sempre, na interface abstrata
      def executar(metodo, url, cabecalhos: {}, corpo: nil)
        raise NotImplementedError, "#{self.class} deve implementar #executar"
      end
    end
  end
end
