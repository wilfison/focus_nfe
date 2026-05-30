# frozen_string_literal: true

RSpec.describe FocusNfe::Configuracao do
  describe "valores padrão" do
    it "usa homologação, timeouts numéricos e cabeçalhos vazios" do
      expect(described_class.new).to have_attributes(
        token: nil, ambiente: :homologacao, timeout: 30, open_timeout: 10,
        logger: nil, adaptador_http: nil, cabecalhos: {}
      )
    end
  end

  describe "atributos" do
    it "aceita todos os atributos via argumentos nomeados" do
      logger = Object.new
      config = described_class.new(token: "t", ambiente: :producao, timeout: 5,
                                   open_timeout: 2, logger: logger, cabecalhos: { "X" => "1" })

      expect(config).to have_attributes(token: "t", ambiente: :producao, timeout: 5,
                                        open_timeout: 2, logger: logger, cabecalhos: { "X" => "1" })
    end

    it "permite escrever os atributos após a construção", :aggregate_failures do
      config = described_class.new
      config.token = "token-123"
      config.cabecalhos["X-Foo"] = "bar"

      expect(config.token).to eq("token-123")
      expect(config.cabecalhos).to eq("X-Foo" => "bar")
    end

    it "apenas armazena a referência ao logger nesta fase" do
      logger = Object.new

      expect(described_class.new(logger: logger).logger).to be(logger)
    end
  end

  describe "#url_base" do
    it "resolve a URL de produção" do
      expect(described_class.new(ambiente: :producao).url_base).to eq("https://api.focusnfe.com.br")
    end

    it "resolve a URL de homologação" do
      expect(described_class.new(ambiente: :homologacao).url_base).to eq("https://homologacao.focusnfe.com.br")
    end

    it "levanta ErroDeConfiguracao para ambiente desconhecido" do
      expect { described_class.new(ambiente: :sandbox).url_base }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao)
    end
  end

  describe "#validar!" do
    it "levanta ErroDeConfiguracao quando o token é nil" do
      config = described_class.new(token: nil, ambiente: :producao)

      expect { config.validar! }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao, /token/)
    end

    it "levanta ErroDeConfiguracao quando o token é vazio ou só espaços" do
      config = described_class.new(token: "   ", ambiente: :producao)

      expect { config.validar! }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao, /token/)
    end

    it "levanta ErroDeConfiguracao quando o ambiente é desconhecido" do
      config = described_class.new(token: "t", ambiente: :sandbox)

      expect { config.validar! }.to raise_error(FocusNfe::Erros::ErroDeConfiguracao, /ambiente/)
    end

    it "devolve a própria configuração quando produção é válida" do
      config = described_class.new(token: "t", ambiente: :producao)

      expect(config.validar!).to be(config)
    end

    it "devolve a própria configuração quando homologação é válida" do
      config = described_class.new(token: "t", ambiente: :homologacao)

      expect(config.validar!).to be(config)
    end
  end
end
