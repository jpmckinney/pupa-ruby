module Pupa
  class Processor
    class ResponseStore
      # Stores HTTP responses to Redis.
      #
      # Use the `hiredis` gem for even greater performance.
      class RedisStore
        # @param [String] address the Redis address at which to dump JSON
        #   documents, e.g. `redis://localhost:6379` or `redis:///tmp/redis.sock`
        def initialize(address)
          options = extract_options_from_address(address)

          if defined?(Hiredis)
            options.update(driver: :hiredis)
          end

          @redis = Redis.new(options)
        end

        # Returns whether a file with the given name exists.
        #
        # @param [String] name a key
        # @return [Boolean] whether the store contains an entry for the given key
        def exist?(name)
        end

        # Returns, as JSON, the contents of the file with the given name.
        #
        # @param [String] name a key
        # @return [Hash] the value of the given key
        def read(name)
        end

        # Writes, as JSON, the value to a file with the given name.
        #
        # @param [String] name a key
        # @param [Hash] value a value
        def write(name, value)
        end

        # Delete a file with the given name.
        #
        # @param [String] name a key
        def delete(name)
        end

        # Deletes all files in the storage directory.
        def clear
        end

      private

        def namespaced_key(name)
        end

        def extract_options_from_address(address)
          if address[0] = '/'
            {path: address}
          elsif address[/\A(.+):(\d+)\z/]
            {host: $1, port: $2.to_i}
          else
            {host: address}
          end
        end
      end
    end
  end
end
