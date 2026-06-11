# frozen_string_literal: true

RSpec.describe FocusNfe::Cliente do
  describe ".new com token e ambiente" do
    it "constrói uma Configuracao interna a partir dos argumentos", :aggregate_failures do
      cliente = described_class.new(token: "tok", ambiente: :producao)

      expect(cliente.configuracao).to be_a(FocusNfe::Configuracao)
      expect(cliente.configuracao).to have_attributes(token: "tok", ambiente: :producao)
    end

    it "repassa opções extras à Configuracao" do
      cliente = described_class.new(token: "tok", timeout: 5, cabecalhos: { "X" => "1" })

      expect(cliente.configuracao).to have_attributes(timeout: 5, cabecalhos: { "X" => "1" })
    end

    it "usa homologação como ambiente padrão" do
      cliente = described_class.new(token: "tok")

      expect(cliente.configuracao.ambiente).to eq(:homologacao)
    end

    it "valida a configuração, levantando sem token" do
      expect { described_class.new(token: nil) }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao)
    end

    it "valida o ambiente, levantando para um desconhecido" do
      expect { described_class.new(token: "tok", ambiente: :sandbox) }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao)
    end
  end

  describe ".new com uma Configuracao pronta" do
    it "aceita e expõe a própria Configuracao" do
      config = FocusNfe::Configuracao.new(token: "tok")

      expect(described_class.new(config).configuracao).to be(config)
    end

    it "também roda validar!, levantando para config sem token" do
      config = FocusNfe::Configuracao.new(token: nil)

      expect { described_class.new(config) }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao)
    end
  end

  describe "#conexao" do
    subject(:cliente) { described_class.new(token: "tok") }

    it "devolve uma HTTP::Conexao" do
      expect(cliente.conexao).to be_a(FocusNfe::HTTP::Conexao)
    end

    it "memoiza a conexão entre chamadas" do
      primeira = cliente.conexao

      expect(cliente.conexao).to be(primeira)
    end
  end

  describe "isolamento entre clientes" do
    it "não compartilha estado entre clientes distintos", :aggregate_failures do
      loja = described_class.new(token: "loja", ambiente: :producao)
      filial = described_class.new(token: "filial", ambiente: :homologacao)

      expect(loja.configuracao.token).to eq("loja")
      expect(filial.configuracao.token).to eq("filial")
      expect(loja.conexao).not_to be(filial.conexao)
    end
  end

  describe "ausência de acessores de recurso" do
    subject(:cliente) { described_class.new(token: "tok") }

    it "ainda não expõe nfe nem empresas", :aggregate_failures do
      expect(cliente).not_to respond_to(:nfe)
      expect(cliente).not_to respond_to(:empresas)
    end
  end
end
