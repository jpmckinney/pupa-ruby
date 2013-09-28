require 'rubygems'

require 'coveralls'
Coveralls.wear!

require 'multi_xml'
require 'nokogiri'
require 'redis-store'
require 'rspec'
require 'vcr'
require File.dirname(__FILE__) + '/../lib/pupa'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :faraday

  c.around_http_request do |request|
    VCR.use_cassette(Digest::SHA1.hexdigest(request.uri + request.body + request.headers.to_s), &request)
  end
end
