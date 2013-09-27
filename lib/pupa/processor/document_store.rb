module Pupa
  class Processor
    # An JSON document store factory.
    #
    # Heavily inspired by `ActiveSupport::Cache::Store`.
    class DocumentStore
      # Returns a configured JSON document store.
      #
      # Pupa flushes the JSON document store before scraping. If you use Redis,
      # **DO NOT** share a Redis database with Pupa and other applications. You
      # can select a different database than the default `0` for use with Pupa
      # by passing an argument like `redis://localhost:6379/0`.
      #
      # @note Redis support depends on the `redis-activesupport` gem. For better
      #   performance, use the `hiredis` gem as well.
      # @param [String] argument the filesystem directory or Redis address
      #   (e.g. `redis://localhost:6379/0`) in which to dump JSON documents
      # @return a configured JSON document store
      def self.new(argument)
        if argument[%r{\Aredis://}]
          options = {}
          if defined?(Hiredis)
            options.update(driver: :hiredis)
          end
          ActiveSupport::Cache::RedisStore.new(argument, options)
        else
          FileStore.new(argument)
        end
      end
    end
  end
end
