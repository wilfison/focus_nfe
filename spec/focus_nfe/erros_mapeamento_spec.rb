# frozen_string_literal: true

RSpec.describe FocusNfe::Erros do
  describe ".classe_para" do
    {
      400 => FocusNfe::Erros::RequisicaoInvalida,
      401 => FocusNfe::Erros::NaoAutorizado,
      403 => FocusNfe::Erros::Proibido,
      404 => FocusNfe::Erros::NaoEncontrado,
      409 => FocusNfe::Erros::Conflito,
      422 => FocusNfe::Erros::ErroDeValidacao,
      429 => FocusNfe::Erros::LimiteDeRequisicoes
    }.each do |status, classe|
      it "mapeia #{status} para #{classe}" do
        expect(described_class.classe_para(status)).to eq(classe)
      end
    end

    it "mapeia qualquer 5xx para ErroDoServidor", :aggregate_failures do
      expect(described_class.classe_para(500)).to eq(described_class::ErroDoServidor)
      expect(described_class.classe_para(503)).to eq(described_class::ErroDoServidor)
      expect(described_class.classe_para(599)).to eq(described_class::ErroDoServidor)
    end

    it "mapeia status não-2xx não previstos para RespostaInesperada", :aggregate_failures do
      expect(described_class.classe_para(418)).to eq(described_class::RespostaInesperada)
      expect(described_class.classe_para(451)).to eq(described_class::RespostaInesperada)
      expect(described_class.classe_para(300)).to eq(described_class::RespostaInesperada)
    end
  end

  describe ".a_partir_de" do
    def resposta(status:, corpo: nil)
      FocusNfe::HTTP::Resposta.new(
        status: status,
        cabecalhos: { "Content-Type" => "application/json" },
        corpo: corpo
      )
    end

    it "instancia a classe correta conforme o status" do
      erro = described_class.a_partir_de(resposta(status: 422))

      expect(erro).to be_a(described_class::ErroDeValidacao)
    end

    it "preenche status, corpo e resposta a partir da Resposta", :aggregate_failures do
      original = resposta(status: 422, corpo: '{"mensagem":"ref inválida"}')
      erro = described_class.a_partir_de(original)

      expect(erro.status).to eq(422)
      expect(erro.corpo).to eq("mensagem" => "ref inválida")
      expect(erro.resposta).to be(original)
    end

    it "usa RespostaInesperada para status não mapeado" do
      erro = described_class.a_partir_de(resposta(status: 418))

      expect(erro).to be_a(described_class::RespostaInesperada)
    end

    it "produz uma exceção levantável que carrega o status na mensagem" do
      erro = described_class.a_partir_de(resposta(status: 500))

      expect { raise erro }.to raise_error(described_class::ErroDoServidor, /500/)
    end
  end
end
