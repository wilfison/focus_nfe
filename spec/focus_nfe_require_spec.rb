# frozen_string_literal: true

require "open3"

RSpec.describe FocusNfe do
  describe "require \"focus_nfe\" em processo limpo" do
    def constantes
      %w[
        FocusNfe::Client
        FocusNfe::Configuration
        FocusNfe::HTTP::Connection
        FocusNfe::Error
        FocusNfe::Errors::HttpError
        FocusNfe::Errors::ConfigurationError
        FocusNfe::Errors::ConnectionError
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

    it "expõe Client, Configuration, HTTP::Connection, Error e Errors::*" do
      checagem = constantes.map { |const| %(defined?(#{const}) || abort("faltou #{const}")) }.join("; ")
      saida, status = executar_ruby(%(require "focus_nfe"; #{checagem}; print "ok"))

      expect(status).to be_success, saida
    end

    it "não puxa a lib base64 transitivamente" do
      saida, = executar_ruby('require "focus_nfe"; print $LOADED_FEATURES.grep(/base64/).inspect')

      expect(saida).to eq("[]")
    end

    it "monta o Authorization sem depender de base64", :aggregate_failures do
      corpo = 'require "focus_nfe"; print FocusNfe::HTTP::Authentication.header("x").fetch("Authorization")'
      saida, status = executar_ruby(corpo)

      expect(status).to be_success, saida
      expect(saida).to eq("Basic eDo=")
    end

    def carregados(corpo)
      executar_ruby(%(require "focus_nfe"; #{corpo}; print $LOADED_FEATURES.grep(%r{focus_nfe/}).join("\\n"))).first
    end

    it "não carrega nenhum recurso de documento só no require" do
      expect(carregados("")).not_to match(%r{focus_nfe/recursos/})
    end

    it "não carrega os modelos só no require" do
      expect(carregados("")).not_to match(%r{focus_nfe/modelos/})
    end

    it "não carrega a máquina de validação de esquemas só no require" do
      expect(carregados("")).not_to match(%r{focus_nfe/esquemas/(esquema|campo|validador)\.rb})
    end

    it "carrega só o recurso referenciado sob demanda, e suas dependências", :aggregate_failures do
      saida = carregados("FocusNfe::Recursos::NfseNacional")

      expect(saida).to match(%r{focus_nfe/recursos/nfse_nacional\.rb})
      expect(saida).to match(%r{focus_nfe/recursos/base\.rb})
      expect(saida).to match(%r{focus_nfe/recursos/concerns/emitivel\.rb})
    end

    it "não puxa recursos irmãos nem os modelos ao referenciar um recurso", :aggregate_failures do
      saida = carregados("FocusNfe::Recursos::NfseNacional")

      expect(saida).not_to match(%r{focus_nfe/recursos/cte\.rb})
      expect(saida).not_to match(%r{focus_nfe/recursos/nfe\.rb})
      expect(saida).not_to match(%r{focus_nfe/modelos/documento\.rb})
    end
  end
end
