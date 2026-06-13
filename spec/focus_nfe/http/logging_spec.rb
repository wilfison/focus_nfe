# frozen_string_literal: true

require "logger"
require "stringio"

RSpec.describe FocusNfe::HTTP::Logging do
  subject(:logging) { described_class.new(logger) }

  let(:io) { StringIO.new }
  let(:logger) { Logger.new(io).tap { |l| l.level = Logger::DEBUG } }
  let(:output) { io.string }

  let(:authorization) { FocusNfe::HTTP::Authentication.header("segredo").fetch("Authorization") }
  let(:headers) { { "Content-Type" => "application/json", "Authorization" => authorization } }

  describe "logger nil (padrão)" do
    let(:logger) { nil }

    it "é um no-op em todos os métodos", :aggregate_failures do
      expect { logging.request(:get, "https://x/v2/nfe", headers) }.not_to raise_error
      expect { logging.response(:get, "https://x/v2/nfe", 200, 0.1, nil) }.not_to raise_error
      expect { logging.response(:get, "https://x/v2/nfe", 422, 0.1, '{"erro":"x"}') }.not_to raise_error
      expect { logging.failure(:get, "https://x/v2/nfe", StandardError.new("boom"), 0.1) }.not_to raise_error
    end
  end

  describe "#request" do
    before { logging.request(:post, "https://x/v2/nfe", headers) }

    it "registra em nível DEBUG com verbo e URL", :aggregate_failures do
      expect(output).to match(/DEBUG/)
      expect(output).to include("POST")
      expect(output).to include("https://x/v2/nfe")
    end

    it "redige o Authorization e não vaza o valor real", :aggregate_failures do
      expect(output).to include("[FILTERED]")
      expect(output).not_to include(authorization)
      expect(output).not_to include("Basic")
    end

    it "preserva headers não sensíveis" do
      expect(output).to include("Content-Type")
    end
  end

  describe "#response" do
    it "registra 2xx em nível INFO com status e tempo, sem corpo", :aggregate_failures do
      logging.response(:post, "https://x/v2/nfe", 200, 0.123, '{"status":"ok"}')

      expect(output).to match(/INFO/)
      expect(output).to include("200")
      expect(output).to include("123ms")
      expect(output).not_to include('"status":"ok"')
    end

    it "registra não-2xx em nível WARN incluindo o corpo de erro", :aggregate_failures do
      logging.response(:post, "https://x/v2/nfe", 422, 0.05, '{"erro":"ref invalida"}')

      expect(output).to match(/WARN/)
      expect(output).to include("422")
      expect(output).to include("ref invalida")
    end

    it "trunca corpo de erro longo em BODY_MAX" do
      corpo = "x" * (described_class::BODY_MAX + 500)

      logging.response(:post, "https://x/v2/nfe", 500, 0.01, corpo)

      expect(output).not_to include("x" * (described_class::BODY_MAX + 1))
    end
  end

  describe "#failure" do
    it "registra falha de transporte em nível ERROR com a mensagem", :aggregate_failures do
      logging.failure(:get, "https://x/v2/nfe", FocusNfe::Errors::ConnectionError.new("timeout"), 0.2)

      expect(output).to match(/ERROR/)
      expect(output).to include("timeout")
      expect(output).to include("https://x/v2/nfe")
    end
  end
end
