# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ibm_cloud_sdk_core/version"

Gem::Specification.new do |spec|
  spec.name = "ibm_cloud_sdk_core"
  spec.version = IBMCloudSdkCore::VERSION
  spec.authors = ["Mamoon Raja"]

  spec.summary = "Official IBM Cloud SDK core library"
  spec.homepage = "https://www.github.com/IBM"
  spec.licenses = ["Apache-2.0"]
  spec.required_ruby_version = ">= 2.7"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["source_code_uri"] = "https://github.com/IBM/ruby-sdk-core"
    spec.metadata["documentation_uri"] = "https://github.com/IBM/ruby-sdk-core"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["rakefile", "{bin,lib,test}/**/*", "README*"] & `git ls-files -z`.split("\0")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "http", "~> 5.1.1"
  spec.add_runtime_dependency "jwt", "~> 2.2.1"

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "codecov", "~> 0.1"
  spec.add_development_dependency "dotenv", "~> 2.4"
  spec.add_development_dependency "httplog", "~> 1.0"
  spec.add_development_dependency "minitest", "~> 5.11"
  spec.add_development_dependency "minitest-hooks", "~> 1.5"
  spec.add_development_dependency "minitest-reporters", "~> 1.3"
  spec.add_development_dependency "minitest-retry", "~> 0.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", ">=1.40"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "webmock", "~> 3.4"
end
