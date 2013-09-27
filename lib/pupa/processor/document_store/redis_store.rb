module Pupa
  class Processor
    class DocumentStore
      # Stores JSON documents in Redis.
      #
      # Pupa flushes the JSON document store before scraping. If you use Redis,
      # **DO NOT** share a Redis database with Pupa and other applications. You
      # can select a different database than the default `0` for use with Pupa
      # by passing an argument like `redis://localhost:6379/0`.
      #
      # @note Redis support depends on the `redis` gem. For better performance,
      #   use the `hiredis` gem as well.
      class RedisStore
        # @param [String] address the address (e.g. `redis://localhost:6379/0`)
        #   in which to dump JSON documents
        def initialize(address)
          options = {}
          if defined?(Hiredis)
            options.update(driver: :hiredis)
          end
          @redis = Redis::Store::Factory.create(address, options)
        end

        # Returns whether database contains an entry for the given key.
        #
        # @param [String] name a key
        # @return [Boolean] whether the store contains an entry for the given key
        def exist?(name)
          @redis.exists(name)
        end

        # Returns all keys in the database.
        #
        # @return [Array<String>] all keys in the store
        def entries
          @redis.keys('*')
        end

        # Returns, as JSON, the value of the given key.
        #
        # @param [String] name a key
        # @return [Hash] the value of the given key
        def read(name)
          JSON.load(@redis.get(name))
        end

        # Returns, as JSON, the values of the given keys.
        #
        # @param [String] names keys
        # @return [Array<Hash>] the values of the given keys
        def read_multi(names)
          @redis.mget(*names).map{|value| JSON.load(value)}
        end

        # Writes, as JSON, the value to a key.
        #
        # @param [String] name a key
        # @param [Hash] value a value
        def write(name, value)
          @redis.set(name, JSON.dump(value))
        end

        # Delete a key.
        #
        # @param [String] name a key
        def delete(name)
          @redis.del(name)
        end

        # Deletes all keys in the database.
        def clear
          @redis.flushdb
        end
      end
    end
  end
end
