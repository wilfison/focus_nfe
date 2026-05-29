# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

desc "Pull fields from FocusNFe API and save to JSON files"
task :pull_fields do
  sh "ruby #{File.join(__dir__, "scripts", "pull_fields.rb")}"
end

RuboCop::RakeTask.new
task default: :rubocop
