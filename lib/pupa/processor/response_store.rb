module Pupa
  class Processor
    # An HTTP response store factory.
    #
    # Heavily inspired by `ActiveSupport::Cache::Store`.
    class ResponseStore
      # Returns a configured HTTP response store.
      #
      # @param [String] output_dir the directory or Redis address
      #   (e.g. redis://localhost:6379) in which to dump JSON documents
      # @return a configured HTTP response store
      def self.new(output_dir)
        address = output_dir[%r{\Aredis://(.+)\z}, 1]
        if address
          RedisStore.new(address)
        else
          FileStore.new(output_dir)
        end
      end
    end
  end
end
