# frozen_string_literal: true

require_relative "lib/pumler/version"

Gem::Specification.new do |spec|
  spec.name          = "pumler"
  spec.version       = Pumler::VERSION
  spec.authors       = ["harryuan65"]
  spec.email         = ["harryuan.65@gmail.com"]

  spec.summary       = "ER Model generator for ActiveRecord"
  spec.description   = "Generates ER Model diagrams for your ActiveRecord in Plantuml format"
  spec.homepage      = "https://github.com/harryuan65/Pumler"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'https://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/harryuan65/Pumler"
  spec.metadata["changelog_uri"] = "https://github.com/harryuan65/Pumler/Changelog"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.2"

  spec.add_dependency "activerecord", ">= 4.0.0"
  spec.add_dependency "railties", ">= 4.0.0"
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
