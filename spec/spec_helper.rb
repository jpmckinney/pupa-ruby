require 'rubygems'

require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec'
end

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :faraday
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
end

require 'multi_xml'
require 'nokogiri'
require 'redis-store'
require 'rspec'

Dir["./spec/support/**/*.rb"].each {|f| require f}
require File.dirname(__FILE__) + '/../lib/pupa'

Mongo::Logger.logger.level = Logger::WARN
