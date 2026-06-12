# frozen_string_literal: true

module FocusNfe
  module Recursos
    # NFS-e de padrão nacional recebidas contra um CNPJ. Listagem com
    # sincronização incremental e downloads (incluindo o DANFSe em HTML).
    class NfsesNacionaisRecebidas < Base
      include Concerns::Listavel
      include Concerns::Baixavel
      include Concerns::Notificavel

      caminho_base "nfsens_recebidas"

      # @param chave [String] chave de acesso da NFS-e
      # @return [String] DANFSe em HTML cru
      def baixar_html(chave)
        baixar(chave, formato: :html)
      end
    end
  end
end
