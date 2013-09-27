module Pupa
  class Processor
    # An JSON document store factory.
    #
    # Heavily inspired by `ActiveSupport::Cache::Store`.
    class DocumentStore
      # Returns a configured JSON document store.
      #
      # @param [String] argument the filesystem directory or Redis address
      #   (e.g. `redis://localhost:6379/0`) in which to dump JSON documents
      # @return a configured JSON document store
      def self.new(argument)
        if argument[%r{\Aredis://}]
          RedisStore.new(argument)
        else
          FileStore.new(argument)
        end
      end
    end
  end
end
