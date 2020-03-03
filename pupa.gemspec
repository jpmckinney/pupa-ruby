# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pupa/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "pupa"
  s.version     = Pupa::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James McKinney"]
  s.homepage    = "https://github.com/jpmckinney/pupa-ruby"
  s.summary     = %q{A data scraping framework}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('activesupport', '~> 4.0')
  s.add_runtime_dependency('colored', '~> 1.2')
  s.add_runtime_dependency('faraday_middleware', '~> 0.10.0')
  s.add_runtime_dependency('json-schema', '~> 2.3')
  s.add_runtime_dependency('mail')
  s.add_runtime_dependency('mongo', '~> 2.0')
  s.add_runtime_dependency('oj', '~> 2.1')
  s.add_runtime_dependency('sequel', '~> 4.10.0')
  s.add_runtime_dependency('pg', '~> 1.0')

  s.add_development_dependency('coveralls')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 3.0')

  s.add_development_dependency('dalli')
  s.add_development_dependency('multi_xml')
  s.add_development_dependency('nokogiri', '~> 1.6')
  s.add_development_dependency('octokit') # to update Popolo schema
  s.add_development_dependency('redis-store')
  s.add_development_dependency('sqlite3')
  s.add_development_dependency('typhoeus')
end
