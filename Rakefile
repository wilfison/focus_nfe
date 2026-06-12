# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

YARD::Rake::YardocTask.new(:yard)

task default: %i[spec rubocop]

desc "Pull fields from FocusNFe API and save to JSON files"
task :pull_fields do
  sh "ruby #{File.join(__dir__, "tools", "pull_fields.rb")}"
end

namespace :docs do
  desc "Gera a documentação YARD em doc/ e abre no navegador"
  task open: :yard do
    report = File.join(__dir__, "doc", "index.html")
    abort "Documentação não encontrada. Rode `bundle exec rake yard` primeiro." unless File.exist?(report)

    sh browser_opener, report
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
