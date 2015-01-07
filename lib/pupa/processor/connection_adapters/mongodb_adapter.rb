require 'moped'

module Pupa
  class Processor
    class Connection
      # A proxy class to save plain old Ruby objects to MongoDB.
      class MongoDBAdapter
        attr_reader :raw_connection

        # @param [String] database_url the database URL
        def initialize(database_url)
          uri = URI.parse(database_url)
          @raw_connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
          @raw_connection.login(uri.user, uri.password) if uri.user && uri.password
        end

        # Finds a document matching the selection criteria.
        #
        # The selection criteria *must* set a `_type` key in order to determine
        # the collection to query.
        #
        # @param [Hash] selector the selection criteria
        # @return [Hash,nil] the matched document, or nil
        # @raises [Pupa::Errors::TooManyMatches] if multiple documents are found
        def find(selector)
          collection_name = collection_name_from_class_name(selector[:_type].camelize)
          if selector.except(:_type).empty?
            raise Errors::EmptySelectorError, "selector is empty during find in collection #{collection_name}"
          end
          collection = raw_connection[collection_name]
          query = collection.find(selector)

          case query.count
          when 0
            nil
          when 1
            query.first
          else
            raise Errors::TooManyMatches, "selector matches multiple documents during find in collection #{collection_name}: #{JSON.dump(selector)}"
          end
        end

        # Inserts or replaces a document in MongoDB.
        #
        # @param [Object] object an object
        # @return [Array] whether the object was inserted and the object's database ID
        # @raises [Pupa::Errors::TooManyMatches] if multiple documents would be updated
        def save(object)
          selector = object.fingerprint

          collection_name = collection_name_from_class_name(object.class.to_s)
          if selector.empty?
            raise Errors::EmptySelectorError, "selector is empty during save in collection #{collection_name} for #{object._id}"
          end
          collection = raw_connection[collection_name]
          query = collection.find(selector)

          # Run query before callbacks to avoid e.g. timestamps in the selector.
          case query.count
          when 0
            object.run_callbacks(:save) do
              object.run_callbacks(:create) do
                collection.insert(object.to_h(persist: true))
                [true, object._id.to_s]
              end
            end
          when 1
            # Make the document available to the callbacks.
            # @see https://github.com/jpmckinney/pupa-ruby/issues/17
            object.document = query.first
            object.run_callbacks(:save) do
              query.update(object.to_h(persist: true).except(:_id))
              [false, object.document['_id'].to_s]
            end
          else
            raise Errors::TooManyMatches, "selector matches multiple documents during save in collection #{collection_name} for #{object._id}: #{JSON.dump(selector)}"
          end
        end

      private

        # Returns the name of the collection in which to save the object.
        #
        # @param [String] class_name the name of the object's class
        # @return [String] the name of the collection in which to save the object
        def collection_name_from_class_name(class_name)
          class_name.demodulize.underscore.pluralize.to_sym
        end
      end
    end
  end
end
