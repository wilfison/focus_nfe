# frozen_string_literal: true

RSpec.describe FocusNfe do
  describe ".configure" do
    it "cede uma Configuration para o bloco" do
      cedida = nil
      described_class.configure { |config| cedida = config }

      expect(cedida).to be_a(FocusNfe::Configuration)
    end

    it "memoiza a configuração ajustada no bloco", :aggregate_failures do
      described_class.configure do |config|
        config.token_empresa = "tok-global"
        config.environment = :producao
      end

      expect(described_class.configuration).to have_attributes(token_empresa: "tok-global", environment: :producao)
    end

    it "devolve a configuração global mesmo quando chamado sem bloco" do
      expect(described_class.configure).to be(described_class.configuration)
    end
  end

  describe ".configuration" do
    it "cria uma Configuration default quando ainda não há" do
      expect(described_class.configuration).to be_a(FocusNfe::Configuration)
    end

    it "devolve sempre a mesma instância global" do
      primeira = described_class.configuration

      expect(described_class.configuration).to be(primeira)
    end
  end

  describe ".client" do
    it "constrói um Client a partir da config global" do
      described_class.configure { |config| config.token_empresa = "tok-global" }

      expect(described_class.client).to be_a(FocusNfe::Client)
    end

    it "usa a config global no cliente" do
      described_class.configure { |config| config.token_empresa = "tok-global" }

      expect(described_class.client.configuration).to be(described_class.configuration)
    end

    it "levanta ConfigurationError quando a config global ainda não tem nenhum token" do
      expect { described_class.client }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe ".reset_configuration!" do
    it "limpa o estado global, gerando uma nova instância depois" do
      anterior = described_class.configuration
      described_class.reset_configuration!

      expect(described_class.configuration).not_to be(anterior)
    end
  end

  describe "isolamento entre exemplos" do
    it "não vê o token de um exemplo anterior" do
      expect(described_class.configuration.token_empresa).to be_nil
    end
  end
end
