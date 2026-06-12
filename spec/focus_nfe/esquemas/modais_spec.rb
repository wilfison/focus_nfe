# frozen_string_literal: true

RSpec.describe FocusNfe::Esquemas::Modais do
  describe ".validar" do
    context "quando o documento é discriminado pelo campo modal (CTe)" do
      it "não acusa nada quando o modal aninhado é válido" do
        dados = { "modal" => "01", "modal_rodoviario" => { "rntrc" => "12345678" } }

        expect(described_class.validar("cte", dados)).to eq([])
      end

      it "acusa campo inválido do modal, prefixado pela chave aninhada" do
        dados = { "modal" => "01", "modal_rodoviario" => { "rntrc" => "123" } }

        erros = described_class.validar("cte", dados)

        expect(erros.join).to include("modal_rodoviario.rntrc")
      end

      it "exige o objeto do modal quando o campo modal o indica" do
        erros = described_class.validar("cte", { "modal" => "01" })

        expect(erros.join).to include("modal_rodoviario: campo obrigatório ausente")
      end

      it "seleciona o sub-esquema conforme o código do modal", :aggregate_failures do
        rodoviario = described_class.validar("cte", { "modal" => "01", "modal_rodoviario" => {} })
        aereo = described_class.validar("cte", { "modal" => "02", "modal_aereo" => {} })

        expect(rodoviario.join).to include("rntrc")
        expect(aereo).to eq([])
      end

      it "não valida modal quando o campo modal está ausente" do
        expect(described_class.validar("cte", {})).to eq([])
      end

      it "aceita chaves Symbol no payload" do
        dados = { modal: "01", modal_rodoviario: { rntrc: "12345678" } }

        expect(described_class.validar("cte", dados)).to eq([])
      end
    end

    context "sem discriminador — detecta pela chave presente (MDFe)" do
      it "valida o modal cuja chave está presente no payload" do
        erros = described_class.validar("mdfe", { "modal_rodoviario" => {} })

        expect(erros.join).to include("modal_rodoviario.")
      end

      it "não acusa nada quando nenhuma chave de modal está presente" do
        expect(described_class.validar("mdfe", { "cnpj_emitente" => "12345678000123" })).to eq([])
      end
    end

    context "quando o documento não tem modal configurado" do
      it "devolve lista vazia" do
        expect(described_class.validar("nfe", { "modal" => "01" })).to eq([])
      end
    end
  end
end
