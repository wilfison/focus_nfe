# frozen_string_literal: true

RSpec.describe FocusNfe::Client do
  describe ".new com tokens e ambiente" do
    it "constrói uma Configuration interna a partir dos argumentos", :aggregate_failures do
      client = described_class.new(token_empresa: "te", token_conta: "tc", environment: :producao)

      expect(client.configuration).to be_a(FocusNfe::Configuration)
      expect(client.configuration).to have_attributes(token_empresa: "te", token_conta: "tc", environment: :producao)
    end

    it "repassa opções extras à Configuration" do
      client = described_class.new(token_empresa: "te", timeout: 5, headers: { "X" => "1" })

      expect(client.configuration).to have_attributes(timeout: 5, headers: { "X" => "1" })
    end

    it "usa homologação como ambiente padrão" do
      client = described_class.new(token_empresa: "te")

      expect(client.configuration.environment).to eq(:homologacao)
    end

    it "valida a configuração, levantando sem nenhum token" do
      expect { described_class.new(token_empresa: nil, token_conta: nil) }
        .to raise_error(FocusNfe::Errors::ConfigurationError)
    end

    it "aceita um cliente só com token de empresa" do
      expect { described_class.new(token_empresa: "te") }.not_to raise_error
    end

    it "aceita um cliente só com token de conta" do
      expect { described_class.new(token_conta: "tc") }.not_to raise_error
    end

    it "valida o ambiente, levantando para um desconhecido" do
      expect { described_class.new(token_empresa: "te", environment: :sandbox) }
        .to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe ".new com uma Configuration pronta" do
    it "aceita e expõe a própria Configuration" do
      config = FocusNfe::Configuration.new(token_empresa: "te")

      expect(described_class.new(config).configuration).to be(config)
    end

    it "também roda validate!, levantando para config sem token" do
      config = FocusNfe::Configuration.new(token_empresa: nil, token_conta: nil)

      expect { described_class.new(config) }.to raise_error(FocusNfe::Errors::ConfigurationError)
    end
  end

  describe "#connection" do
    subject(:client) { described_class.new(token_empresa: "te") }

    it "devolve uma HTTP::Connection" do
      expect(client.connection).to be_a(FocusNfe::HTTP::Connection)
    end

    it "memoiza a conexão entre chamadas" do
      primeira = client.connection

      expect(client.connection).to be(primeira)
    end

    it "levanta ConfigurationError sem token_empresa" do
      client = described_class.new(token_conta: "tc")

      expect { client.connection }.to raise_error(FocusNfe::Errors::ConfigurationError, /token_empresa/)
    end
  end

  describe "#connection_conta" do
    subject(:client) { described_class.new(token_conta: "tc") }

    it "devolve uma HTTP::Connection distinta da de empresa", :aggregate_failures do
      client = described_class.new(token_empresa: "te", token_conta: "tc")

      expect(client.connection_conta).to be_a(FocusNfe::HTTP::Connection)
      expect(client.connection_conta).not_to be(client.connection)
    end

    it "memoiza a conexão entre chamadas" do
      primeira = client.connection_conta

      expect(client.connection_conta).to be(primeira)
    end

    it "levanta ConfigurationError sem token_conta" do
      client = described_class.new(token_empresa: "te")

      expect { client.connection_conta }.to raise_error(FocusNfe::Errors::ConfigurationError, /token_conta/)
    end
  end

  describe "roteamento de token por escopo" do
    subject(:client) { described_class.new(token_empresa: "te", token_conta: "tc") }

    let(:json) { { "Content-Type" => "application/json" } }

    def homologacao = "https://homologacao.focusnfe.com.br"

    def authorization(token)
      FocusNfe::HTTP::Authentication.header(token).fetch("Authorization")
    end

    it "usa o token da empresa nos recursos fiscais" do
      stub = stub_request(:get, "#{homologacao}/v2/nfe/ref-1")
             .with(headers: { "Authorization" => authorization("te") })
             .to_return(status: 200, body: "{}", headers: json)

      client.nfe.consultar("ref-1")

      expect(stub).to have_been_requested
    end

    it "usa o token da conta nas consultas auxiliares" do
      stub = stub_request(:get, "#{homologacao}/v2/ceps/69909032")
             .with(headers: { "Authorization" => authorization("tc") })
             .to_return(status: 200, body: "{}", headers: json)

      client.ceps.consultar("69909032")

      expect(stub).to have_been_requested
    end

    it "usa o token da conta na gestão de empresas" do
      stub = stub_request(:get, "#{homologacao}/v2/empresas/7")
             .with(headers: { "Authorization" => authorization("tc") })
             .to_return(status: 200, body: "{}", headers: json)

      client.empresas.consultar("7")

      expect(stub).to have_been_requested
    end
  end

  describe "token ausente por escopo" do
    it "levanta ao acessar recurso de conta sem token_conta" do
      client = described_class.new(token_empresa: "te")

      expect { client.ceps }.to raise_error(FocusNfe::Errors::ConfigurationError, /token_conta/)
    end

    it "levanta ao acessar recurso fiscal sem token_empresa" do
      client = described_class.new(token_conta: "tc")

      expect { client.nfe }.to raise_error(FocusNfe::Errors::ConfigurationError, /token_empresa/)
    end
  end

  describe "isolamento entre clientes" do
    it "não compartilha estado entre clientes distintos", :aggregate_failures do
      loja = described_class.new(token_empresa: "loja", environment: :producao)
      filial = described_class.new(token_empresa: "filial", environment: :homologacao)

      expect(loja.configuration.token_empresa).to eq("loja")
      expect(filial.configuration.token_empresa).to eq("filial")
      expect(loja.connection).not_to be(filial.connection)
    end
  end

  describe "acessores de recurso" do
    subject(:client) { described_class.new(token_empresa: "te", token_conta: "tc") }

    {
      nfe: FocusNfe::Recursos::Nfe,
      nfce: FocusNfe::Recursos::Nfce,
      nfse: FocusNfe::Recursos::Nfse,
      nfse_nacional: FocusNfe::Recursos::NfseNacional,
      cte: FocusNfe::Recursos::Cte,
      cte_os: FocusNfe::Recursos::CteOs,
      mdfe: FocusNfe::Recursos::Mdfe,
      nfcom: FocusNfe::Recursos::Nfcom,
      dce: FocusNfe::Recursos::Dce,
      nfgas: FocusNfe::Recursos::Nfgas,
      nfes_recebidas: FocusNfe::Recursos::NfesRecebidas,
      ctes_recebidas: FocusNfe::Recursos::CtesRecebidas,
      nfses_nacionais_recebidas: FocusNfe::Recursos::NfsesNacionaisRecebidas,
      ceps: FocusNfe::Recursos::Ceps,
      municipios: FocusNfe::Recursos::Municipios,
      cfops: FocusNfe::Recursos::Cfops,
      cnaes: FocusNfe::Recursos::Cnaes,
      ncms: FocusNfe::Recursos::Ncms,
      cnpjs: FocusNfe::Recursos::Cnpjs,
      empresas: FocusNfe::Recursos::Empresas,
      webhooks: FocusNfe::Recursos::Webhooks,
      emails_bloqueados: FocusNfe::Recursos::EmailsBloqueados,
      backups: FocusNfe::Recursos::Backups
    }.each do |acessor, classe|
      describe "##{acessor}" do
        it "devolve um #{classe}" do
          expect(client.public_send(acessor)).to be_a(classe)
        end

        it "memoiza o recurso entre chamadas" do
          primeiro = client.public_send(acessor)

          expect(client.public_send(acessor)).to be(primeiro)
        end
      end
    end
  end
end
