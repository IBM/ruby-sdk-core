# frozen_string_literal: true

require("simplecov")
require("simplecov-cobertura")
require("minitest/reporters")

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter if ENV["CI"]
SimpleCov.start do
  add_filter "/test/"
  add_filter do |src_file|
    File.basename(src_file.filename) == "version.rb"
  end

  command_name "Minitest"
end

require("minitest/autorun")
require_relative("./../lib/ibm_cloud_sdk_core")
require("minitest/retry")

Minitest::Retry.use!

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true, slow_count: 10), Minitest::Reporters::SpecReporter.new, Minitest::Reporters::HtmlReporter.new] if ENV["CI"].nil?
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true, slow_count: 10), Minitest::Reporters::SpecReporter.new] if ENV["CI"]
