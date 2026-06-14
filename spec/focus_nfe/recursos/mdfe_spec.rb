# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Mdfe do
  let(:ref) { "manifesto-7" }

  it_behaves_like "um recurso emitível", "mdfe"
  it_behaves_like "um recurso consultável", "mdfe"
  it_behaves_like "um recurso cancelável", "mdfe"

  include_context "com recurso conectado"

  describe "#encerrar" do
    it "faz POST em /v2/mdfe/{ref}/encerrar com data, UF e município", :aggregate_failures do
      stub = stub_envio(:post, "mdfe/#{ref}/encerrar",
                        body: { data: "2026-06-13", sigla_uf: "SP", nome_municipio: "São Paulo" })

      doc = recurso.encerrar(ref, data: "2026-06-13", sigla_uf: "SP", nome_municipio: "São Paulo")

      expect(stub).to have_been_requested
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end

    it "rejeita ref inválida sem requisição" do
      expect { recurso.encerrar("manifesto 7", data: "2026-06-13", sigla_uf: "SP", nome_municipio: "São Paulo") }
        .to raise_error(ArgumentError)
    end

    context "quando o ambiente é produção" do
      let(:client) { FocusNfe::Client.new(token_empresa: "tok", environment: :producao) }

      it "usa o host de produção" do
        stub = stub_request(:post, "https://api.focusnfe.com.br/v2/mdfe/#{ref}/encerrar")
               .to_return(status: 200, body: "{}", headers: json)

        recurso.encerrar(ref, data: "2026-06-13", sigla_uf: "SP", nome_municipio: "São Paulo")

        expect(stub).to have_been_requested
      end
    end
  end

  describe "#incluir_condutor" do
    it "faz POST em /v2/mdfe/{ref}/inclusao_condutor com nome e CPF", :aggregate_failures do
      stub = stub_envio(:post, "mdfe/#{ref}/inclusao_condutor", body: { nome: "João", cpf: "12345678912" })

      doc = recurso.incluir_condutor(ref, nome: "João", cpf: "12345678912")

      expect(stub).to have_been_requested
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end
  end

  describe "#incluir_dfe" do
    let(:documentos) do
      [{ "chave_nfe" => "3" * 44, "codigo_municipio_descarregamento" => "3550308" }]
    end

    it "faz POST em /v2/mdfe/{ref}/inclusao_dfe com protocolo, município e documentos", :aggregate_failures do
      stub = stub_envio(:post, "mdfe/#{ref}/inclusao_dfe",
                        body: { protocolo: "141250000012345",
                                codigo_municipio_carregamento: "3550308",
                                documentos: documentos })

      doc = recurso.incluir_dfe(ref, protocolo: "141250000012345",
                                     codigo_municipio_carregamento: "3550308",
                                     documentos: documentos)

      expect(stub).to have_been_requested
      expect(doc).to be_a(FocusNfe::Modelos::Documento)
    end

    it "inclui nome_municipio_carregamento no corpo quando informado" do
      stub = stub_envio(:post, "mdfe/#{ref}/inclusao_dfe",
                        body: { protocolo: "141250000012345",
                                codigo_municipio_carregamento: "3550308",
                                documentos: documentos,
                                nome_municipio_carregamento: "São Paulo" })

      recurso.incluir_dfe(ref, protocolo: "141250000012345",
                               codigo_municipio_carregamento: "3550308",
                               documentos: documentos,
                               nome_municipio_carregamento: "São Paulo")

      expect(stub).to have_been_requested
    end

    it "omite nome_municipio_carregamento do corpo quando não informado" do
      stub_envio(:post, "mdfe/#{ref}/inclusao_dfe")

      recurso.incluir_dfe(ref, protocolo: "141250000012345",
                               codigo_municipio_carregamento: "3550308",
                               documentos: documentos)

      requisicao = a_request(:post, "#{homologacao}/v2/mdfe/#{ref}/inclusao_dfe")
                   .with { |req| !req.body.include?("nome_municipio_carregamento") }
      expect(requisicao).to have_been_made
    end
  end
end
