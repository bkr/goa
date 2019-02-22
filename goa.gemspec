# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goa/version'

Gem::Specification.new do |spec|
  spec.name          = "goa"
  spec.version       = GOA::VERSION
  spec.authors       = ["Michael Pearce"]
  spec.email         = ["michael.pearce@bookrenter.com"]
  spec.description   = %q{Gem Oriented Architecture - Share ActiveRecord Models with a Rails Engine}
  spec.summary       = %q{Share ActiveRecord models that use a different database connection across separate Rails applications.}
  spec.homepage      = "https://github.com/bkr/goa"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "database_cleaner", "~> 0.8.0"
end
