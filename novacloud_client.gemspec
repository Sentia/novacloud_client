# frozen_string_literal: true

require_relative "lib/novacloud_client/version"

Gem::Specification.new do |spec|
  spec.name = "novacloud_client"
  spec.version = NovacloudClient::VERSION
  spec.authors = ["Chayut Orapinpatipat"]
  spec.email = ["chayut@canopusnet.com"]

  spec.summary = "Ruby client for the NovaCloud API."
  spec.description = "A Faraday-based Ruby client for the NovaCloud Open Platform that handles authentication, error mapping, and resource abstractions."
  spec.homepage = "https://github.com/canopusnet/novacloud_client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/canopusnet/novacloud_client/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "bin"
  spec.executables = []
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_runtime_dependency "faraday", "~> 2.7"

  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
