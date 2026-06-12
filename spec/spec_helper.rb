# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch

  add_filter "/spec/"
  add_filter "/tools/"
  add_filter "lib/focus_nfe/version.rb"

  add_group "Recursos", "lib/focus_nfe/recursos"
  add_group "Esquemas", "lib/focus_nfe/esquemas"
  add_group "HTTP", "lib/focus_nfe/http"
  add_group "Modelos", "lib/focus_nfe/modelos"
end

require "focus_nfe"

require "webmock/rspec"
require "vcr"

# Nenhuma requisição HTTP real é permitida durante os testes (ver CLAUDE.md).
WebMock.disable_net_connect!(allow_localhost: false)

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: :none }
end

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |file| require file }

RSpec.configure do |config|
  # Habilita a sintaxe `expect` apenas.
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Permite focar exemplos com `fit`/`fdescribe` e roda tudo se nenhum estiver focado.
  config.filter_run_when_matching :focus

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before { FocusNfe.reset_configuration! }
end
