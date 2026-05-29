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
