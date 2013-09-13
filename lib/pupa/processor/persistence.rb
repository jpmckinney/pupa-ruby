module Pupa
  class Processor
    # A proxy class to persist plain old Ruby objects to MongoDB.
    class Persistence
      # @param [Object] object an object
      def initialize(object)
        @object = object
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
            raise Errors::TooManyMatches, "selector matches multiple documents: #{selector.inspect}"
          end
        end
      end

    private

      # Returns the name of the collection in which to store the object.
      #
      # @return [String] the name of the collection in which to store the object
      def collection_name
        @object.class.to_s.demodulize.underscore.pluralize.to_sym
      end

      # Returns the collection in which to store the object.
      #
      # @return [Moped::Collection] the collection in which to store the object
      def collection
        Pupa.session[collection_name]
      end
    end
  end
end
