require 'rubygems'

require 'coveralls'
Coveralls.wear!

require 'multi_xml'
require 'nokogiri'
require 'redis-store'
require 'rspec'
require File.dirname(__FILE__) + '/../lib/pupa'

def testing_python_compatibility?
  ENV['MODE'] == 'compat'
end

if testing_python_compatibility?
  require File.dirname(__FILE__) + '/../lib/pupa/refinements/opencivicdata'
end

RSpec.configure do |c|
  c.filter_run_excluding :testing_python_compatibility => true unless testing_python_compatibility?
end
