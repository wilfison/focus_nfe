# frozen_string_literal: true

RSpec.describe FocusNfe::Configuration do
  describe "valores padrão" do
    it "usa homologação, timeouts numéricos, tokens nil e cabeçalhos vazios" do
      expect(described_class.new).to have_attributes(
        token_empresa: nil, token_conta: nil, environment: :homologacao, timeout: 30,
        open_timeout: 10, logger: nil, http_adapter: nil, headers: {}
      )
    end
  end

  describe "atributos" do
    it "aceita todos os atributos via argumentos nomeados" do
      logger = Object.new
      config = described_class.new(token_empresa: "te", token_conta: "tc", environment: :producao,
                                   timeout: 5, open_timeout: 2, logger: logger, headers: { "X" => "1" })

      expect(config).to have_attributes(token_empresa: "te", token_conta: "tc", environment: :producao,
                                        timeout: 5, open_timeout: 2, logger: logger, headers: { "X" => "1" })
    end

    it "permite escrever os tokens após a construção", :aggregate_failures do
      config = described_class.new
      config.token_empresa = "te-123"
      config.token_conta = "tc-123"

      expect(config).to have_attributes(token_empresa: "te-123", token_conta: "tc-123")
    end

    it "apenas armazena a referência ao logger nesta fase" do
      logger = Object.new

      expect(described_class.new(logger: logger).logger).to be(logger)
    end
  end

  describe "#token_de" do
    it "resolve o token de cada escopo", :aggregate_failures do
      config = described_class.new(token_empresa: "te", token_conta: "tc")

      expect(config.token_de(:empresa)).to eq("te")
      expect(config.token_de(:conta)).to eq("tc")
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
    it "levanta ConfigurationError quando nenhum token está presente" do
      config = described_class.new(token_empresa: nil, token_conta: nil, environment: :producao)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /token/)
    end

    it "levanta ConfigurationError quando os tokens são vazios ou só espaços" do
      config = described_class.new(token_empresa: "   ", token_conta: "", environment: :producao)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /token/)
    end

    it "aceita apenas o token de empresa" do
      config = described_class.new(token_empresa: "te", environment: :producao)

      expect(config.validate!).to be(config)
    end

    it "aceita apenas o token de conta" do
      config = described_class.new(token_conta: "tc", environment: :producao)

      expect(config.validate!).to be(config)
    end

    it "levanta ConfigurationError quando o ambiente é desconhecido" do
      config = described_class.new(token_empresa: "te", environment: :sandbox)

      expect { config.validate! }.to raise_error(FocusNfe::Errors::ConfigurationError, /ambiente/)
    end
  end

  describe "#validate_token!" do
    it "devolve a própria configuração quando o token do escopo está presente" do
      config = described_class.new(token_empresa: "te", token_conta: "tc")

      expect(config.validate_token!(:empresa)).to be(config)
    end

    it "levanta ConfigurationError citando token_empresa quando o escopo :empresa não tem token" do
      config = described_class.new(token_conta: "tc")

      expect { config.validate_token!(:empresa) }
        .to raise_error(FocusNfe::Errors::ConfigurationError, /token_empresa/)
    end

    it "levanta ConfigurationError citando token_conta quando o escopo :conta não tem token" do
      config = described_class.new(token_empresa: "te")

      expect { config.validate_token!(:conta) }
        .to raise_error(FocusNfe::Errors::ConfigurationError, /token_conta/)
    end

    it "valida o ambiente antes do token" do
      config = described_class.new(token_empresa: "te", environment: :sandbox)

      expect { config.validate_token!(:empresa) }
        .to raise_error(FocusNfe::Errors::ConfigurationError, /ambiente/)
    end
  end
end
