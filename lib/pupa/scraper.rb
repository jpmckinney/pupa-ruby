require 'forwardable'
require 'json'

require 'nokogiri'

require 'pupa/client'
require 'pupa/logger'
require 'pupa/yielder'

module Pupa
  # An abstract scraper class from which specific scrapers inherit.
  class Scraper
    extend Forwardable
    include Helper

    attr_reader :output_dir, :cache_dir

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    def initialize(output_dir, cache_dir)
      @output_dir = output_dir
      @cache_dir  = cache_dir
      @logger     = Logger.new('pupa')
      @client     = Client.new(cache_dir)
    end

    # Retrieves and parses a document with a GET request.
    #
    # @param [String] url a URL to an HTML document
    # @param [String,Hash] params query string parameters
    # @return a parsed document
    def get(url, params = {})
      # Faraday requires `params` to be a hash.
      if String === params
        params = CGI.parse(params)

        # Flatten the parameters for Faraday.
        params.each do |key,value|
          if Array === value && value.size == 1
            params[key] = value.first
          end
        end
      end

      @client.get(url, params).body
    end

    # Retrieves and parses a document with a POST request.
    #
    # @param [String] url a URL to an HTML document
    # @param [String,Hash] params query string parameters
    # @return a parsed document
    def post(url, params = {})
      @client.post(url, params).body
    end

    # Defines a method named after `type`, e.g. "organizations", which memoizes
    # the return value of a method named e.g. "scrape_organizations".
    #
    # @param [Symbol] type a type of scrapable object 
    def self.register(type)
      define_method(type) do
        ivar = "@#{type}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          instance_variable_set(ivar, Yielder.new(&method("scrape_#{type}")))
        end
      end
    end

    # Scrapes and saves objects to disk.
    #
    # @param [Symbol] type the type of object to scrape
    def scrape(type)
      # @todo implement importer stuff (get_db_spec, import_from_json)
      send(type).each do |object|
        save_object(object)
      end
    end

    # Saves a scraped object to disk.
    #
    # @param [Object] object a scraped object
    def save_object(object)
      type = object.class.to_s.demodulize.downcase
      basename = "#{type}_#{object.id}.json"
      info("save #{type} #{object.to_s} as #{basename}")

      File.open(File.join(output_dir, basename), 'w') do |f|
        f.write(JSON.dump(object.to_h))
      end

      begin
        object.validate!
      rescue JSON::Schema::ValidationError => e
        warn(e)
      end
    end
  end
end
