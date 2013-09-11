require 'forwardable'
require 'json'

require 'nokogiri'

require 'pupa/client'
require 'pupa/logger'
require 'pupa/yielder'

module Pupa
  # An abstract processor class from which specific processors inherit.
  # @todo go through Python Pupa's importers/base.py
  class Processor
    extend Forwardable
    include Helper

    attr_reader :output_dir, :cache_dir, :expires_in, :options

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    # @param [String] output_dir the directory in which to save JSON documents
    # @param [String] cache_dir the directory in which to cache HTTP responses
    # @param [Integer] expires_in the cache's expiration time in seconds
    # @param [Hash] kwargs criteria for selecting the methods to run
    def initialize(output_dir, cache_dir: nil, expires_in: 86400, **kwargs)
      @output_dir = output_dir
      @cache_dir  = cache_dir
      @expires_in = expires_in
      @options    = kwargs
      @logger     = Logger.new('pupa')
      @client     = Client.new(cache_dir, expires_in)
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

    # Adds an extraction (scraping) task to Pupa.rb.
    #
    # Defines a method whose name is identical to `task_name`. This method
    # selects a method to perform the eponymous task using `extract_task_method`
    # and memoizes its return value. The return value is a lazy enumerator of
    # objects extracted by the selected method. The selected method must yield
    # objects to populate this lazy enumerator.
    #
    # For example, `Pupa::Processor.add_extract_task(:people)` defines a `people`
    # method on `Pupa::Processor`, which all subclasses inherit. This `people`
    # method returns a lazy enumerator of objects (presumably Person objects in
    # this case, but the enumerator can contain any object in the general case).
    #
    # In a subclass of `Pupa::Processor`, you would define either a specific
    # `extract_people` method or a generic `extract` method, which must yield
    # objects to populate the lazy enumerator. Alternatively, you may override
    # `extract_task_method` to change the method selected to perform the task.
    #
    # The `people` method can then be called by transformation tasks.
    #
    # @param [Symbol] task_name a task name
    # @see Pupa::Processor#extract_task_method
    def self.add_extract_task(task_name)
      define_method(task_name) do
        ivar = "@#{task_name}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          instance_variable_set(ivar, Yielder.new(&method(extract_task_method(task_name)))
        end
      end
    end

    # Returns the name of the method that would be used to perform the given
    # extraction task.
    #
    # If your processor defines a `extract_<task_name>` method, that method will
    # be selected to perform the task. Otherwise, the generic `extract` method
    # will be selected.
    #
    # If you would like to change this default behavior, override this method in
    # a subclass. For example, you may want to select a method according to the
    # additional `options` passed from the command-line to the processor.
    #
    # @param [Symbol] task_name a task name
    # @return [String] the name of the method that would be used to perform the
    #   given extraction task
    def extract_task_method(task_name)
      method_name = "extract_#{task_name}"
      if respond_to?(method_name)
        method_name
      else
        'extract'
      end
    end

    # Returns the name of the method that would be used to perform the given
    # load task.
    #
    # @param [Symbol] task_name a task name
    # @return [String] the name of the method that would be used to perform the
    #   given load task
    def load_task_method(task_name)
      'save_to_file'
    end

    # Loads extracted objects into an end target.
    #
    # @param [Symbol] task_name the name of the task to perform
    def load(task_name)
      send(task_name).each do |object|
        method(load_task_method(task_name)).call(object)
      end
    end

    # Saves an extracted object to disk.
    #
    # @param [Object] object an extracted object
    def save_to_file(object)
      type = object.class.to_s.demodulize.downcase
      basename = "#{type}_#{object.id}.json"
      info("save #{type} #{object.to_s} as #{basename}")

      File.open(File.join(@output_dir, basename), 'w') do |f|
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
