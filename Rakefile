# frozen_string_literal: true

require "dotenv/tasks"
require "rake/testtask"
require "rubocop/rake_task"

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.name = "test"
  t.description = "Run unit tests"
  t.libs << "test"
  t.test_files = FileList["test/unit/*.rb"]
  t.verbose = true
  t.warning = true
  t.deps = [:rubocop]
end

task default: :test
