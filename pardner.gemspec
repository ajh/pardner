# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pardner/version'

Gem::Specification.new do |spec|
  spec.name          = 'pardner'
  spec.version       = Pardner::VERSION
  spec.authors       = ['Andy Hartford']
  spec.email         = ['andy.hartford@cohealo.com']

  spec.summary       = 'A decorator library for ActiveRecord'
  spec.description   = 'A decorator library for ActiveRecord that has features to fit in nicely with the ActiveModel world'
  spec.homepage      = 'https://github.com/ajh/pardner'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
    .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activemodel',   '~> 4.2'
  spec.add_runtime_dependency 'activerecord',  '~> 4.2'
  spec.add_runtime_dependency 'activesupport', '~> 4.2'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake',    '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'sqlite3'

  # guard stuff
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rb-fsevent'
  spec.add_development_dependency 'rb-inotify'
  spec.add_development_dependency 'ruby_gntp'
end
