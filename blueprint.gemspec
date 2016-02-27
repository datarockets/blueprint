# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blueprint/version'

Gem::Specification.new do |spec|
  spec.name          = 'blueprint'
  spec.version       = Blueprint::VERSION
  spec.authors       = ['Datarockets']
  spec.email         = ['hello@datarockets.com']

  spec.summary       = 'Rails application generator'
  spec.description   = 'Generate application with custom settings'
  spec.homepage      = 'https://github.com/datarockets/blueprint'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['blueprint']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  %w(rspec simplecov rubocop pry rspec-shell-expectations).each do |dependecy|
    spec.add_development_dependency dependecy
  end

  %w(commander).each do |dependecy|
    spec.add_dependency dependecy
  end
end
