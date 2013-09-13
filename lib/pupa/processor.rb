require 'json'

require 'nokogiri'

require 'pupa/processor/client'
require 'pupa/processor/dependency_graph'
require 'pupa/processor/persistence'
require 'pupa/processor/yielder'

module Pupa
  class MissingTargetIdError < Error; end
  class DuplicateObjectIdError < Error; end

  # An abstract processor class from which specific processors inherit.
  class Processor
    extend Forwardable
    include Helper

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    # @param [String] output_dir the directory in which to save JSON documents
    # @param [String] cache_dir the directory in which to cache HTTP responses
    # @param [Integer] expires_in the cache's expiration time in seconds
    # @param [Hash] kwargs criteria for selecting the methods to run
    def initialize(output_dir, cache_dir: nil, expires_in: 86400, **kwargs)
      @output_dir = output_dir
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

    # Loads extracted objects into an end target.
    #
    # @raises [TSort::Cyclic] if the dependency graph is cyclic
    # @raises [MissingTargetIdError] if a foreign key cannot be resolved
    def load
      objects = load_extracted_objects

      losers_to_winners = build_losers_to_winners_map(objects)

      # Remove all losers.
      losers_to_winners.each_key do |key|
        objects.delete(key)
      end

      dependency_graph = DependencyGraph.new

      # Swap the IDs of losers for the IDs of winners and build a dependency graph.
      objects.each do |id,object|
        if dependency_graph.key?(id)
          raise DuplicateObjectIdError, "duplicate object ID: #{id}"
        else
          dependency_graph[id] = []
          object.foreign_keys.each do |foreign_key|
            foreign_id = object[foreign_key]
            if losers_to_winners.key?(foreign_id)
              foreign_id = losers_to_winners[foreign_id]
              object[foreign_key] = foreign_id
            end
            dependency_graph[id] << foreign_id
          end
        end
      end

      object_id_to_target_id = {}

      # Replace object IDs with database IDs in foreign keys and save objects.
      dependency_graph.tsort.each do |id|
        objects[id].foreign_keys.each do |foreign_key|
          object_id = object[foreign_key]
          if object_id_to_target_id.key?(object_id)
            object[foreign_key] = object_id_to_target_id[object_id]
          else
            raise MissingTargetIdError, "missing target ID: #{foreign_key} #{object_id} of #{id}"
          end
        end
        object_id_to_target_id[id] = Persistence.new(objects[id]).save
      end

      # Ensure that fingerprints uniquely identified objects.
      counts = {}
      object_id_to_target_id.each do |object_id,target_id|
        (counts[target_id] ||= []) << object_id
      end
      duplicates = counts.select do |_,object_ids|
        object_ids.size > 1
      end
      unless duplicates.empty?
        raise "multiple objects saved to same target:\n" + duplicates.map{|target_id,object_ids| "  #{target_id} <- #{object_ids.join(' ')}"}.join("\n")
      end
    end

  private

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
    # @return [String] the name of the method to perform the extraction task
    def extract_task_method(task_name)
      method_name = "extract_#{task_name}"
      if respond_to?(method_name)
        method_name
      else
        'extract'
      end
    end

    # Loads extracted objects from an intermediate data store.
    #
    # @return [Hash] a hash of extracted objects keyed by ID
    def load_extracted_objects
      objects = {}
      Dir[File.join(@output_dir, '*.json')].each do |path|
        data = JSON.load(File.read(path))
        object = data['_type'].camelize.constantize.new(data)
        objects[object._id] = object
      end
      objects
    end

    # Dumps extracted objects to an intermediate data store.
    #
    # @param [Symbol] task_name the name of the extraction task to perform
    def dump_extracted_objects(task_name)
      send(task_name).each do |object|
        dump_extracted_object(object)
      end
    end

    # Dumps an extracted object to disk.
    #
    # @param [Object] object an extracted object
    def dump_extracted_object(object)
      type = object.class.to_s.demodulize.underscore
      basename = "#{type}_#{object._id}.json"
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

    # For each object, map its ID to the ID of its duplicate, if any.
    #
    # @param [Hash] objects a hash of extracted objects keyed by ID
    # @return [Hash] a mapping from an object ID to the ID of its duplicate
    def build_losers_to_winners_map(objects)
      map = {}
      objects.each_with_index do |(id1,object1),index|
        unless map.key?(id1) # Don't search for duplicates of duplicates.
          objects.drop(index + 1).each do |id2,object2|
            if object1 == object2
              map[id2] = id1
            end
          end
        end
      end
      map
    end
  end
end
