module Pupa
  class Processor
    # A proxy class to save plain old Ruby objects to MongoDB.
    class Persistence
      # @param [Object] object an object
      def initialize(object)
        @object = object
      end

      # Finds a document matching the selection criteria.
      #
      # The selection criteria *must* set a `_type` key in order to determine
      # the collection to query.
      #
      # @param [Hash] selector the selection criteria
      # @return [Hash,nil] the matched document, or nil
      # @raises [Pupa::Errors::TooManyMatches] if multiple documents are found
      def self.find(selector)
        query = Pupa.session[collection_name_from_class_name(selector['_type'].camelize)].find(selector)
        case query.count
        when 0
          nil
        when 1
          query.first
        else
          raise Errors::TooManyMatches, "selector matches multiple documents during find: #{selector.inspect}"
        end
      end

      # Saves an object to MongoDB.
      #
      # @return [String] the object's database ID
      # @raises [Pupa::Errors::TooManyMatches] if multiple documents would be updated
      def save
        @object.run_callbacks(:save) do
          selector = @object.fingerprint
          query = collection.find(selector)
          case query.count
          when 0
            @object.run_callbacks(:create) do
              collection.insert(@object.to_h)
              @object._id.to_s
            end
          when 1
            document = query.first
            query.update(@object.to_h)
            document._id.to_s
          else
            raise Errors::TooManyMatches, "selector matches multiple documents during save: #{selector.inspect}"
          end
        end
      end

    private

      # Returns the name of the collection in which to save the object.
      #
      # @return [String] the name of the object's class
      def self.collection_name_from_class_name(class_name)
        class_name.demodulize.underscore.pluralize.to_sym
      end

      # Returns the name of the collection in which to save the object.
      #
      # @return [String] the name of the collection in which to save the object
      def collection_name
        self.class.collection_name_from_class_name(@object.class.to_s)
      end

      # Returns the collection in which to save the object.
      #
      # @return [Moped::Collection] the collection in which to save the object
      def collection
        Pupa.session[collection_name]
      end
    end
  end
end
