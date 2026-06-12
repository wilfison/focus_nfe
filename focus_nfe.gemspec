# frozen_string_literal: true

require_relative "lib/focus_nfe/version"

Gem::Specification.new do |spec|
  spec.name = "focus_nfe"
  spec.version = FocusNfe::VERSION
  spec.authors = ["wilfison"]
  spec.email = ["wilfisonbatista@gmail.com"]

  spec.summary = "Cliente Ruby não-oficial para a API da Focus NFe."
  spec.description = "Cliente Ruby não-oficial para a API da Focus NFe (focusnfe.com.br), " \
                     "serviço brasileiro de emissão de documentos fiscais eletrônicos. Cobre os " \
                     "documentos emitidos (NFe, NFCe, NFSe, NFSe nacional, CTe, CTe OS, MDFe, NFCom, " \
                     "DCe, NFGas), recebidos, APIs auxiliares (CEP, CNPJ, municípios, CFOP, CNAE, NCM) " \
                     "e de gestão (empresas, webhooks). Suporta multi-empresa, erros tipados por " \
                     "status HTTP e validação client-side opt-in por schemas, sem dependências de runtime."
  spec.homepage = "https://github.com/wilfison/focus_nfe"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wilfison/focus_nfe"
  spec.metadata["changelog_uri"] = "https://github.com/wilfison/focus_nfe/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # Dependências de desenvolvimento e teste
  spec.add_development_dependency "overcommit", "~> 0.71"
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.86"
  spec.add_development_dependency "rubocop-performance", "~> 1.25"
  spec.add_development_dependency "rubocop-rspec", "~> 3.6"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "vcr", "~> 6.3"
  spec.add_development_dependency "webmock", "~> 3.25"
  spec.add_development_dependency "webrick", "~> 1.9"
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
