# frozen_string_literal: true

RSpec.describe FocusNfe do
  describe ".configurar" do
    it "cede uma Configuracao para o bloco" do
      cedida = nil
      described_class.configurar { |config| cedida = config }

      expect(cedida).to be_a(FocusNfe::Configuracao)
    end

    it "memoiza a configuração ajustada no bloco", :aggregate_failures do
      described_class.configurar do |config|
        config.token = "tok-global"
        config.ambiente = :producao
      end

      expect(described_class.configuracao).to have_attributes(token: "tok-global", ambiente: :producao)
    end
  end

  describe ".configuracao" do
    it "cria uma Configuracao default quando ainda não há" do
      expect(described_class.configuracao).to be_a(FocusNfe::Configuracao)
    end

    it "devolve sempre a mesma instância global" do
      primeira = described_class.configuracao

      expect(described_class.configuracao).to be(primeira)
    end
  end

  describe ".cliente" do
    it "constrói um Cliente a partir da config global" do
      described_class.configurar { |config| config.token = "tok-global" }

      expect(described_class.cliente).to be_a(FocusNfe::Cliente)
    end

    it "usa a config global no cliente" do
      described_class.configurar { |config| config.token = "tok-global" }

      expect(described_class.cliente.configuracao).to be(described_class.configuracao)
    end

    it "levanta ErroDeConfiguracao quando a config global ainda não tem token" do
      expect { described_class.cliente }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao)
    end
  end

  describe ".resetar_configuracao!" do
    it "limpa o estado global, gerando uma nova instância depois" do
      anterior = described_class.configuracao
      described_class.resetar_configuracao!

      expect(described_class.configuracao).not_to be(anterior)
    end
  end

  describe "isolamento entre exemplos" do
    it "não vê o token de um exemplo anterior" do
      expect(described_class.configuracao.token).to be_nil
    end
  end
end
