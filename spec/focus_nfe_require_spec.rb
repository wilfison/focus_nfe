# frozen_string_literal: true

require "open3"

RSpec.describe FocusNfe do
  describe "require \"focus_nfe\" em processo limpo" do
    def constantes
      %w[
        FocusNfe::Cliente
        FocusNfe::Configuracao
        FocusNfe::HTTP::Conexao
        FocusNfe::Erro
        FocusNfe::Erros::ErroHttp
        FocusNfe::Erros::ErroDeConfiguracao
        FocusNfe::Erros::ErroDeConexao
      ]
    end

    def executar_ruby(corpo)
      lib = File.expand_path("../lib", __dir__)
      env = ENV.to_h
      %w[RUBYOPT BUNDLE_GEMFILE BUNDLER_SETUP].each { |chave| env.delete(chave) }

      Open3.capture2e(env, RbConfig.ruby, "--disable-gems", "-I#{lib}", "-e", corpo)
    end

    it "carrega sem levantar", :aggregate_failures do
      saida, status = executar_ruby('require "focus_nfe"; print "ok"')

      expect(status).to be_success
      expect(saida).to eq("ok")
    end

    it "expõe Cliente, Configuracao, HTTP::Conexao, Erro e Erros::*" do
      checagem = constantes.map { |const| %(defined?(#{const}) || abort("faltou #{const}")) }.join("; ")
      saida, status = executar_ruby(%(require "focus_nfe"; #{checagem}; print "ok"))

      expect(status).to be_success, saida
    end

    it "não puxa a lib base64 transitivamente" do
      saida, = executar_ruby('require "focus_nfe"; print $LOADED_FEATURES.grep(/base64/).inspect')

      expect(saida).to eq("[]")
    end

    it "monta o Authorization sem depender de base64", :aggregate_failures do
      corpo = 'require "focus_nfe"; print FocusNfe::HTTP::Autenticacao.cabecalho("x").fetch("Authorization")'
      saida, status = executar_ruby(corpo)

      expect(status).to be_success, saida
      expect(saida).to eq("Basic eDo=")
    end
  end
end
