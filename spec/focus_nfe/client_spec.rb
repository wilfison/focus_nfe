# frozen_string_literal: true

RSpec.describe FocusNfe::Client do
  describe ".new com token e ambiente" do
    it "constrói uma Configuration interna a partir dos argumentos", :aggregate_failures do
      client = described_class.new(token: "tok", environment: :producao)

      expect(client.configuration).to be_a(FocusNfe::Configuration)
      expect(client.configuration).to have_attributes(token: "tok", environment: :producao)
    end

    it "repassa opções extras à Configuration" do
      client = described_class.new(token: "tok", timeout: 5, headers: { "X" => "1" })

      expect(client.configuration).to have_attributes(timeout: 5, headers: { "X" => "1" })
    end

    it "usa homologação como ambiente padrão" do
      client = described_class.new(token: "tok")

      expect(client.configuration.environment).to eq(:homologacao)
    end

    it "valida a configuração, levantando sem token" do
      expect { described_class.new(token: nil) }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end

    it "valida o ambiente, levantando para um desconhecido" do
      expect { described_class.new(token: "tok", environment: :sandbox) }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe ".new com uma Configuration pronta" do
    it "aceita e expõe a própria Configuration" do
      config = FocusNfe::Configuration.new(token: "tok")

      expect(described_class.new(config).configuration).to be(config)
    end

    it "também roda validate!, levantando para config sem token" do
      config = FocusNfe::Configuration.new(token: nil)

      expect { described_class.new(config) }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe "#connection" do
    subject(:client) { described_class.new(token: "tok") }

    it "devolve uma HTTP::Connection" do
      expect(client.connection).to be_a(FocusNfe::HTTP::Connection)
    end

    it "memoiza a conexão entre chamadas" do
      primeira = client.connection

      expect(client.connection).to be(primeira)
    end
  end

  describe "isolamento entre clientes" do
    it "não compartilha estado entre clientes distintos", :aggregate_failures do
      loja = described_class.new(token: "loja", environment: :producao)
      filial = described_class.new(token: "filial", environment: :homologacao)

      expect(loja.configuration.token).to eq("loja")
      expect(filial.configuration.token).to eq("filial")
      expect(loja.connection).not_to be(filial.connection)
    end
  end

  describe "#nfe" do
    subject(:client) { described_class.new(token: "tok") }

    it "devolve um Recursos::Nfe" do
      expect(client.nfe).to be_a(FocusNfe::Recursos::Nfe)
    end

    it "memoiza o recurso entre chamadas" do
      primeiro = client.nfe

      expect(client.nfe).to be(primeiro)
    end
  end

  describe "acessores de recurso ainda não implementados" do
    subject(:client) { described_class.new(token: "tok") }

    it "ainda não expõe empresas" do
      expect(client).not_to respond_to(:empresas)
    end
  end
end
