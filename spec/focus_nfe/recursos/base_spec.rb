# frozen_string_literal: true

RSpec.describe FocusNfe::Recursos::Base do
  let(:connection) { instance_double(FocusNfe::HTTP::Connection) }

  describe "DSL caminho_base" do
    it "expõe o caminho declarado na classe via método de instância" do
      classe = Class.new(described_class) { caminho_base "nfe" }

      expect(classe.new(connection).caminho_base).to eq("nfe")
    end

    it "é por classe — subclasses não vazam entre si", :aggregate_failures do
      uma = Class.new(described_class) { caminho_base "nfe" }
      outra = Class.new(described_class) { caminho_base "nfce" }

      expect(uma.new(connection).caminho_base).to eq("nfe")
      expect(outra.new(connection).caminho_base).to eq("nfce")
    end
  end

  describe "#validar_referencia!" do
    subject(:recurso) { Class.new(described_class) { caminho_base "nfe" }.new(connection) }

    it "aceita refs alfanuméricas com hífen/underscore", :aggregate_failures do
      expect { recurso.send(:validar_referencia!, "pedido-42") }.not_to raise_error
      expect { recurso.send(:validar_referencia!, "venda_1001") }.not_to raise_error
    end

    it "rejeita refs com espaço ou vazias", :aggregate_failures do
      expect { recurso.send(:validar_referencia!, "a b") }.to raise_error(ArgumentError)
      expect { recurso.send(:validar_referencia!, "") }.to raise_error(ArgumentError)
      expect { recurso.send(:validar_referencia!, nil) }.to raise_error(ArgumentError)
    end
  end

  describe "#caminho_referencia" do
    subject(:recurso) { Class.new(described_class) { caminho_base "nfe" }.new(connection) }

    it "combina o caminho base com a ref" do
      expect(recurso.send(:caminho_referencia, "pedido-42")).to eq("nfe/pedido-42")
    end
  end
end
