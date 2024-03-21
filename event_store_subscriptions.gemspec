# frozen_string_literal: true

require_relative "lib/event_store_subscriptions/version"

Gem::Specification.new do |spec|
  spec.name          = "event_store_subscriptions"
  spec.version       = EventStoreSubscriptions::VERSION
  spec.authors       = ["Ivan Dzyzenko"]
  spec.email         = ["ivan.dzyzenko@gmail.com"]

  spec.summary       = "Implementation of subscription manager for `event_store_client` gem."
  spec.description   = "Implementation of subscription manager for `event_store_client` gem."
  spec.homepage      = "https://github.com/yousty/event_store_subscriptions"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yousty/event_store_subscriptions"

  spec.files = Dir['{lib}/**/*', 'LICENSE.txt', 'README.md', 'docs/**/*']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "event_store_client", '~> 3.0.0'

  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rake', '~> 13.0'
end
