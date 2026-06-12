# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "Pull fields from FocusNFe API and save to JSON files"
task :pull_fields do
  sh "ruby #{File.join(__dir__, "scripts", "pull_fields.rb")}"
end

namespace :coverage do
  desc "Abre o relatório de cobertura do SimpleCov no navegador"
  task :open do
    report = File.join(__dir__, "coverage", "index.html")
    abort "Relatório não encontrado. Rode `bundle exec rake spec` primeiro." unless File.exist?(report)

    opener =
      if RUBY_PLATFORM.include?("darwin") then "open"
      elsif RUBY_PLATFORM.match?(/mswin|mingw|cygwin/) then "start"
      else "xdg-open"
      end

    sh opener, report
  end
end
