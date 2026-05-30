# frozen_string_literal: true

RSpec.describe FocusNfe::Erros do
  describe "FocusNfe::Erro (raiz da hierarquia)" do
    it "descende de StandardError" do
      expect(FocusNfe::Erro.new).to be_a(StandardError)
    end

    it "substitui a antiga FocusNfe::Error (inglês), que deixa de existir" do
      expect(FocusNfe.const_defined?(:Error, false)).to be(false)
    end
  end

  describe FocusNfe::Erros::ErroHttp do
    it "descende de FocusNfe::Erro" do
      expect(described_class.ancestors).to include(FocusNfe::Erro)
    end

    it "expõe status, corpo e resposta informados na construção" do
      resposta = Object.new
      erro = described_class.new("falhou", status: 422, corpo: { "msg" => "ref" }, resposta: resposta)

      expect(erro).to have_attributes(message: "falhou", status: 422, corpo: { "msg" => "ref" }, resposta: resposta)
    end

    it "pode ser construído sem argumentos, com leitores nil", :aggregate_failures do
      erro = described_class.new

      expect(erro.status).to be_nil
      expect(erro.corpo).to be_nil
      expect(erro.resposta).to be_nil
    end
  end

  describe "subclasses tipadas de ErroHttp" do
    %i[
      RequisicaoInvalida NaoAutorizado Proibido NaoEncontrado Conflito
      ErroDeValidacao LimiteDeRequisicoes ErroDoServidor RespostaInesperada
    ].each do |nome|
      it "#{nome} descende de ErroHttp, Erro e StandardError", :aggregate_failures do
        classe = described_class.const_get(nome)

        expect(classe.ancestors).to include(FocusNfe::Erros::ErroHttp)
        expect(classe.ancestors).to include(FocusNfe::Erro)
        expect(classe.ancestors).to include(StandardError)
      end
    end

    it "reúnem exatamente 9 classes distintas, sem aliasing" do
      todas = described_class.constants.map { |nome| described_class.const_get(nome) }
      subclasses = todas.select { |const| const.is_a?(Class) && const < described_class::ErroHttp }

      expect(subclasses.uniq.size).to eq(9)
    end
  end

  describe "erros não-HTTP (client-side e transporte)" do
    it "ErroDeConfiguracao descende de Erro, mas não de ErroHttp", :aggregate_failures do
      ancestrais = FocusNfe::Erros::ErroDeConfiguracao.ancestors

      expect(ancestrais).to include(FocusNfe::Erro)
      expect(ancestrais).not_to include(FocusNfe::Erros::ErroHttp)
    end

    it "ErroDeConexao descende de Erro, mas não de ErroHttp", :aggregate_failures do
      ancestrais = FocusNfe::Erros::ErroDeConexao.ancestors

      expect(ancestrais).to include(FocusNfe::Erro)
      expect(ancestrais).not_to include(FocusNfe::Erros::ErroHttp)
    end
  end
end
