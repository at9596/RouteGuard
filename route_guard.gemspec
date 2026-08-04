# frozen_string_literal: true

require_relative "lib/route_guard/version"

Gem::Specification.new do |spec|
  spec.name          = "route_guard"
  spec.version       = RouteGuard::VERSION
  spec.authors       = ["Amritesh Tiwari"]
  spec.email         = ["t.amritesh801@gmail.com"]

  spec.summary       = "A production-ready static analysis tool for Rails routes."
  spec.description   = "Analyze Rails routes for shadowing, duplicates, unreachable routes, and maintainability metrics."
  spec.homepage      = "https://github.com/amriteshtiwari/RouteGuard"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z 2>/dev/null`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:test|spec|features)/})
    end
  end
  # Fallback if git fails or is not in repository context
  spec.files = Dir["lib/**/*.rb", "bin/*", "LICENSE.txt", "README.md"] if spec.files.empty?

  spec.bindir        = "bin"
  spec.executables   = ["route_guard"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rainbow", "~> 3.1"
  spec.add_dependency "thor", "~> 1.2"

  # We depend on rails/actionpack for routing APIs
  spec.add_dependency "actionpack", ">= 6.1"
  spec.add_dependency "railties", ">= 6.1"

  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
