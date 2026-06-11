# frozen_string_literal: true

RSpec.describe FocusNfe::Configuration do
  describe "valores padrão" do
    it "usa homologação, timeouts numéricos e cabeçalhos vazios" do
      expect(described_class.new).to have_attributes(
        token: nil, environment: :homologacao, timeout: 30, open_timeout: 10,
        logger: nil, http_adapter: nil, headers: {}
      )
    end
  end

  describe "atributos" do
    it "aceita todos os atributos via argumentos nomeados" do
      logger = Object.new
      config = described_class.new(token: "t", environment: :producao, timeout: 5,
                                   open_timeout: 2, logger: logger, headers: { "X" => "1" })

      expect(config).to have_attributes(token: "t", environment: :producao, timeout: 5,
                                        open_timeout: 2, logger: logger, headers: { "X" => "1" })
    end

    it "permite escrever os atributos após a construção", :aggregate_failures do
      config = described_class.new
      config.token = "token-123"
      config.headers["X-Foo"] = "bar"

      expect(config.token).to eq("token-123")
      expect(config.headers).to eq("X-Foo" => "bar")
    end

    it "apenas armazena a referência ao logger nesta fase" do
      logger = Object.new

      expect(described_class.new(logger: logger).logger).to be(logger)
    end
  end

  describe "#base_url" do
    it "resolve a URL de produção" do
      expect(described_class.new(environment: :producao).base_url).to eq("https://api.focusnfe.com.br")
    end

    it "resolve a URL de homologação" do
      expect(described_class.new(environment: :homologacao).base_url).to eq("https://homologacao.focusnfe.com.br")
    end

    it "levanta ConfigurationError para ambiente desconhecido" do
      expect { described_class.new(environment: :sandbox).base_url }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe "#validate!" do
    it "levanta ConfigurationError quando o token é nil" do
      config = described_class.new(token: nil, environment: :producao)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /token/)
    end

    it "levanta ConfigurationError quando o token é vazio ou só espaços" do
      config = described_class.new(token: "   ", environment: :producao)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /token/)
    end

    it "levanta ConfigurationError quando o ambiente é desconhecido" do
      config = described_class.new(token: "t", environment: :sandbox)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /ambiente/)
    end

    it "devolve a própria configuração quando produção é válida" do
      config = described_class.new(token: "t", environment: :producao)

      expect(config.validate!).to be(config)
    end

    it "devolve a própria configuração quando homologação é válida" do
      config = described_class.new(token: "t", environment: :homologacao)

      expect(config.validate!).to be(config)
    end
  end
end
