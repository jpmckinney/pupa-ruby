require 'json'

require 'nokogiri'

require 'pupa/processor/client'
require 'pupa/processor/dependency_graph'
require 'pupa/processor/helper'
require 'pupa/processor/persistence'
require 'pupa/processor/yielder'

module Pupa
  # An abstract processor class from which specific processors inherit.
  class Processor
    extend Forwardable
    include Helper

    class_attribute :tasks
    self.tasks = []

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    # @param [String] output_dir the directory in which to dump JSON documents
    # @param [String] cache_dir the directory in which to cache HTTP responses
    # @param [Integer] expires_in the cache's expiration time in seconds
    # @param [String] level the log level
    # @param [String,IO] logdev the log device
    # @param [Hash] options criteria for selecting the methods to run
    def initialize(output_dir, cache_dir: nil, expires_in: 86400, level: 'INFO', logdev: STDOUT, options: {})
      @output_dir = output_dir
      @options    = options
      @level      = level
      @logger     = Logger.new('pupa', level: level, logdev: logdev)
      @client     = Client.new(cache_dir: cache_dir, expires_in: expires_in, level: level)
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

    # Adds a scraping task to Pupa.rb.
    #
    # Defines a method whose name is identical to `task_name`. This method
    # selects a method to perform the scraping task using `scraping_task_method`
    # and memoizes its return value. The return value is a lazy enumerator of
    # objects scraped by the selected method. The selected method must yield
    # objects to populate this lazy enumerator.
    #
    # For example, `MyProcessor.add_scraping_task(:people)` defines a `people`
    # method on `MyProcessor`. This `people` method returns a lazy enumerator of
    # objects (presumably Person objects in this case, but the enumerator can
    # contain any object in the general case).
    #
    # In `MyProcessor`, you would define an `scrape_people` method, which must
    # yield objects to populate the lazy enumerator. Alternatively, you may
    # override `scraping_task_method` to change the method selected to perform
    # the scraping task.
    #
    # The `people` method can then be called by transformation and import tasks.
    #
    # @param [Symbol] task_name a task name
    # @see Pupa::Processor#scraping_task_method
    def self.add_scraping_task(task_name)
      self.tasks += [task_name]
      define_method(task_name) do
        ivar = "@#{task_name}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          instance_variable_set(ivar, Yielder.new(&method(scraping_task_method(task_name))))
        end
      end
    end

    # Dumps scraped objects to disk.
    #
    # @param [Symbol] task_name the name of the scraping task to perform
    def dump_scraped_objects(task_name)
      send(task_name).each do |object|
        dump_scraped_object(object)
      end
    end

    # Saves scraped objects to a database.
    #
    # @raises [TSort::Cyclic] if the dependency graph is cyclic
    # @raises [Pupa::Errors::UnprocessableEntity] if an object's foreign keys or
    #   foreign objects cannot be resolved
    # @raises [Pupa::Errors::DuplicateDocumentError] if duplicate objects were
    #   inadvertently saved to the database
    def import
      objects = deduplicate(load_scraped_objects)

      object_id_to_database_id = {}

      if use_dependency_graph?(objects)
        dependency_graph = build_dependency_graph(objects)

        # Replace object IDs with database IDs in foreign keys and save objects.
        dependency_graph.tsort.each do |id|
          object = objects[id]
          resolve_foreign_keys(object, object_id_to_database_id)
          # The dependency graph strategy only works if there are no foreign objects.
          object_id_to_database_id[id] = Persistence.new(object).save
        end
      else
        size = objects.size

        # Should be O(n²). If there are foreign objects, we do not know all the
        # edges in the graph, and therefore cannot build a dependency graph or
        # derive any evaluation order.
        #
        # An exception is raised if a foreign object matches multiple documents
        # in the database. However, if a matching object is not yet saved, this
        # exception may not be raised.
        loop do
          progress_made = false

          objects.delete_if do |id,object|
            resolvable = true

            resolvable &= object.foreign_keys.all? do |property|
              value = object[property]
              value.nil? || object_id_to_database_id.key?(value)
            end

            resolvable &= object.foreign_objects.all? do |property|
              selector = object[property]
              selector.blank? || Persistence.find(selector)
            end

            if resolvable
              progress_made = true
              resolve_foreign_keys(object, object_id_to_database_id)
              resolve_foreign_objects(object)
              object_id_to_database_id[id] = Persistence.new(object).save
            end
          end

          break if objects.empty? || !progress_made
        end

        unless objects.empty?
          raise Errors::UnprocessableEntity, "couldn't resolve #{objects.size}/#{size} objects:\n  #{objects.values.map{|object| JSON.dump(object.foreign_properties)}.join("\n  ")}"
        end
      end

      # Ensure that fingerprints uniquely identified objects.
      counts = {}
      object_id_to_database_id.each do |object_id,database_id|
        (counts[database_id] ||= []) << object_id
      end
      duplicates = counts.select do |_,object_ids|
        object_ids.size > 1
      end
      unless duplicates.empty?
        raise Errors::DuplicateDocumentError, "multiple objects written to same document:\n" + duplicates.map{|database_id,object_ids| "  #{database_id} <- #{object_ids.join(' ')}"}.join("\n")
      end
    end

  private

    # Returns the name of the method - `scrape_<task_name>` by default - that
    # would be used to perform the given scraping task.
    #
    # If you would like to change this default behavior, override this method in
    # a subclass. For example, you may want to select a method according to the
    # additional `options` passed from the command-line to the processor.
    #
    # @param [Symbol] task_name a task name
    # @return [String] the name of the method to perform the scraping task
    def scraping_task_method(task_name)
      "scrape_#{task_name}"
    end

    # Dumps an scraped object to disk.
    #
    # @param [Object] object an scraped object
    # @raises [Pupa::Errors::DuplicateObjectIdError]
    def dump_scraped_object(object)
      type = object.class.to_s.demodulize.underscore
      basename = "#{type}_#{object._id}.json"
      path = File.join(@output_dir, basename)

      if File.exist?(path)
        raise Errors::DuplicateObjectIdError, "duplicate object ID: #{object._id} (was the same objected yielded twice?)"
      end

      info {"save #{type} #{object.to_s} as #{basename}"}

      File.open(path, 'w') do |f|
        f.write(JSON.dump(object.to_h(include_foreign_objects: true)))
      end

      begin
        object.validate!
      rescue JSON::Schema::ValidationError => e
        warn {e.message}
      end
    end

    # Loads scraped objects from disk.
    #
    # @return [Hash] a hash of scraped objects keyed by ID
    def load_scraped_objects
      {}.tap do |objects|
        Dir[File.join(@output_dir, '*.json')].each do |path|
          data = JSON.load(File.read(path))
          object = data['_type'].camelize.constantize.new(data)
          objects[object._id] = object
        end
      end
    end

    # Removes all duplicate objects and re-assigns any foreign keys.
    #
    # @param [Hash] objects a hash of scraped objects keyed by ID
    # @return [Hash] the objects without duplicates
    def deduplicate(objects)
      losers_to_winners = build_losers_to_winners_map(objects)

      # Remove all losers.
      losers_to_winners.each_key do |key|
        objects.delete(key)
      end

      # Swap the IDs of losers for the IDs of winners.
      objects.each do |id,object|
        object.foreign_keys.each do |property|
          value = object[property]
          if value && losers_to_winners.key?(value)
            object[property] = losers_to_winners[value]
          end
        end
      end

      objects
    end

    # For each object, map its ID to the ID of its duplicate, if any.
    #
    # @param [Hash] objects a hash of scraped objects keyed by ID
    # @return [Hash] a mapping from an object ID to the ID of its duplicate
    def build_losers_to_winners_map(objects)
      {}.tap do |map|
        objects.each_with_index do |(id1,object1),index|
          unless map.key?(id1) # Don't search for duplicates of duplicates.
            objects.drop(index + 1).each do |id2,object2|
              if object1 == object2
                map[id2] = id1
              end
            end
          end
        end
      end
    end

    # If any objects have unresolved foreign objects, we cannot derive an
    # evaluation order using a dependency graph.
    #
    # @param [Hash] objects a hash of scraped objects keyed by ID
    # @return [Boolean] whether a dependency graph can be used to derive an
    #   evaluation order
    def use_dependency_graph?(objects)
      objects.each do |id,object|
        object.foreign_objects.each do |property|
          if object[property].present?
            return false
          end
        end
      end
      true
    end

    # Builds a dependency graph.
    #
    # @param [Hash] objects a hash of scraped objects keyed by ID
    # @return [DependencyGraph] the dependency graph
    def build_dependency_graph(objects)
      DependencyGraph.new.tap do |graph|
        objects.each do |id,object|
          graph[id] = [] # no duplicate IDs
          object.foreign_keys.each do |property|
            value = object[property]
            if value
              graph[id] << value
            end
          end
        end
      end
    end

    # Resolves an object's foreign keys from object IDs to database IDs.
    #
    # @param [Object] an object
    # @param [Hash] a map from object ID to database ID
    # @raises [Pupa::Errors::MissingDatabaseIdError]
    def resolve_foreign_keys(object, map)
      object.foreign_keys.each do |property|
        value = object[property]
        if value
          # If using a dependency graph, any foreign key that cannot be resolved
          # will cause a key error while building the dependency graph.
          #
          # If not using a dependency graph, this method will not be called
          # unless the foreign key is resolvable.
          object[property] = map[value]
        end
      end
    end

    # Resolves an object's foreign objects to database IDs.
    #
    # @param [Object] an object
    # @raises [Pupa::Errors::MissingDatabaseIdError]
    def resolve_foreign_objects(object)
      object.foreign_objects.each do |property|
        selector = object[property]
        if selector.present?
          # This method will not be called unless the foreign key is resolvable.
          object["#{property}_id"] = Persistence.find(selector)['_id']
        end
      end
    end
  end
end
