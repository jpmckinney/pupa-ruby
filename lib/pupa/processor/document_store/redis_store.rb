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
      # @note Redis support depends on the `redis-store` gem. You may optionally
      #   use the `hiredis` gem to further improve performance.
      class RedisStore
        # @param [String] address the address (e.g. `redis://localhost:6379/0`)
        #   in which to dump JSON documents
        # @param [Boolean] pipelined whether to enable
        #   [pipelining](http://redis.io/topics/pipelining)
        def initialize(address, pipelined: false)
          @pipelined = pipelined
          options = {serializer: nil}
          options.update(driver: :hiredis) if defined?(Hiredis)
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
          Oj.load(@redis.get(name))
        end

        # Returns, as JSON, the values of the given keys.
        #
        # @param [String] names keys
        # @return [Array<Hash>] the values of the given keys
        def read_multi(names)
          @redis.mget(*names).map{|value| Oj.load(value)}
        end

        # Writes, as JSON, the value to a key.
        #
        # @param [String] name a key
        # @param [Hash] value a value
        def write(name, value)
          @redis.set(name, Oj.dump(value, mode: :compat, time_format: :ruby))
        end

        # Writes, as JSON, the value to a key, unless the key exists.
        #
        # @param [String] name a key
        # @param [Hash] value a value
        # @return [Boolean] whether the key was set
        def write_unless_exists(name, value)
          @redis.setnx(name, Oj.dump(value, mode: :compat, time_format: :ruby))
        end

        # Writes, as JSON, the values to keys.
        #
        # @param [Hash] pairs key-value pairs
        def write_multi(pairs)
          args = []
          pairs.each do |key,value|
            args << key
            args << Oj.dump(value, mode: :compat, time_format: :ruby)
          end
          @redis.mset(*args)
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

        # Collects commands to run all at once.
        def pipelined
          if @pipelined
            @redis.pipelined do
              yield
            end
          else
            yield
          end
        end
      end
    end
  end
end
