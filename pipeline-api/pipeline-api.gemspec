# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pipeline/api/version'

Gem::Specification.new do |s|
  s.name          = "pipeline-api"
  s.version       = Pipeline::API::VERSION
  s.authors       = ["Kaixiong Ma"]
  s.email         = ["asce0705@gmail.com"]
  s.summary       = "Ruby API for Pipeline."
  s.homepage      = ""
  s.license       = "Apache 2"

  #s.files         = `git ls-files`.split($/)
  s.files	      = Dir['README.md', 'LICENSE.txt', 'Gemfile', 'Rakefile', '{lib,utils}/**/*']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.extra_rdoc_files  = Dir["README.md", "LICENSE.txt"]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.add_dependency "multi_json"

  s.add_development_dependency "bundler", "> 1"

  if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
    s.add_development_dependency "rake", "~> 11.1"
  else
    s.add_development_dependency "rake", "< 11.0"
  end

  s.add_development_dependency "pipeline"
  s.add_development_dependency "pandora-transport"

  if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
    s.add_development_dependency "minitest", "~> 4.0"
  end

  s.add_development_dependency "ansi"
  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "mocha"
  s.add_development_dependency "turn"
  s.add_development_dependency "yard"
  s.add_development_dependency "pry"
  s.add_development_dependency "ci_reporter", "~> 1.9"

  # Gems for testing integrations
  s.add_development_dependency "jsonify"
  s.add_development_dependency "hashie"

  # Prevent unit test failures on Ruby 1.8
  if defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
    s.add_development_dependency "test-unit", '~> 2'
    s.add_development_dependency "json", '~> 1.8'
  end

  if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
    s.add_development_dependency "ruby-prof" unless defined?(JRUBY_VERSION) || defined?(Rubinius)
    s.add_development_dependency "jbuilder"
    s.add_development_dependency "escape_utils" unless defined? JRUBY_VERSION
    s.add_development_dependency "simplecov"
    s.add_development_dependency "simplecov-rcov"
    s.add_development_dependency "cane"
    s.add_development_dependency "require-prof" unless defined?(JRUBY_VERSION) || defined?(Rubinius)
  end

  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'
    s.add_development_dependency "test-unit", '~> 2'
  end

  s.description = <<-DESC.gsub(/^    /, '')
    Ruby API for Pipeline. See the `pipeline` gem for full integration.
  DESC
end
