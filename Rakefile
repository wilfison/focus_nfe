# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

YARD::Rake::YardocTask.new(:yard)

begin
  require "steep/rake_task"
  Steep::RakeTask.new(:steep)
rescue LoadError
  # ambiente sem dependências de desenvolvimento
end

task default: %i[spec rubocop]

desc "Roda localmente as mesmas verificações do CI (.github/workflows/ci.yml)"
task :ci do
  etapas = [
    ["Specs (RSpec)",     -> { Rake::Task["spec"].invoke }],
    ["Lint (RuboCop)",    -> { Rake::Task["rubocop"].invoke }],
    ["Tipos (Steep)",     -> { sh "bundle exec steep check" }],
    ["Docs (YARD)",       -> { sh "bundle exec yard doc --no-output --fail-on-warning" }],
    ["Cobertura de docs", -> { Rake::Task["docs:coverage"].invoke }]
  ]

  falhas = []
  etapas.each do |nome, acao|
    puts "\n\e[1m▶ #{nome}\e[0m"
    acao.call
    puts "\e[32m✓ #{nome}\e[0m"
  rescue SystemExit, StandardError => e
    falhas << nome
    puts "\e[31m✗ #{nome} (#{e.class}: #{e.message})\e[0m"
  end

  puts "\n\e[1mResumo do CI local\e[0m"
  etapas.each do |etapa|
    marcador = falhas.include?(etapa[0]) ? "\e[31m✗\e[0m" : "\e[32m✓\e[0m"
    puts "  #{marcador} #{etapa[0]}"
  end

  abort "\n#{falhas.size} verificação(ões) falharam: #{falhas.join(", ")}" if falhas.any?

  puts "\n\e[32mTudo verde — pronto para enviar ao GitHub.\e[0m"
end

desc "Pull fields from FocusNFe API and save to JSON files"
task :pull_fields do
  sh "ruby #{File.join(__dir__, "tools", "pull_fields.rb")}"
end

COBERTURA_DOCS_MINIMA = 93.0

namespace :docs do
  desc "Gera a documentação YARD em docs/ e abre no navegador"
  task open: :yard do
    report = File.join(__dir__, "docs", "index.html")
    abort "Documentação não encontrada. Rode `bundle exec rake yard` primeiro." unless File.exist?(report)

    sh browser_opener, report
  end

  desc "Falha se a cobertura de documentação YARD ficar abaixo de #{COBERTURA_DOCS_MINIMA}%"
  task :coverage do
    saida = `yard stats --list-undoc`
    puts saida

    cobertura = saida[/([\d.]+)% documented/, 1]&.to_f
    abort "Não foi possível ler a cobertura no resultado do `yard stats`." if cobertura.nil?

    if cobertura < COBERTURA_DOCS_MINIMA
      abort "Cobertura de documentação #{cobertura}% abaixo do mínimo de #{COBERTURA_DOCS_MINIMA}%."
    end

    puts "Cobertura de documentação: #{cobertura}% (mínimo #{COBERTURA_DOCS_MINIMA}%)."
  end

  desc "Sobe o servidor YARD (http://localhost:8808) com refresh automático"
  task :serve do
    sh "yard", "server", "--reload"
  end
end

def browser_opener
  if RUBY_PLATFORM.include?("darwin") then "open"
  elsif RUBY_PLATFORM.match?(/mswin|mingw|cygwin/) then "start"
  else "xdg-open"
  end
end

namespace :coverage do
  desc "Abre o relatório de cobertura do SimpleCov no navegador"
  task :open do
    report = File.join(__dir__, "coverage", "index.html")
    abort "Relatório não encontrado. Rode `bundle exec rake spec` primeiro." unless File.exist?(report)

    sh browser_opener, report
  end
end
