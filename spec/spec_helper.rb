require 'rubygems'

require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec'
end

require 'multi_xml'
require 'nokogiri'
require 'redis-store'
require 'rspec'
require File.dirname(__FILE__) + '/../lib/pupa'
