require 'active_support/cache'
require 'faraday_middleware'
require 'faraday_middleware/response_middleware'

require 'pupa/processor/middleware/logger'
require 'pupa/processor/middleware/parse_html'
require 'pupa/processor/middleware/parse_json'
require 'pupa/refinements/faraday'
require 'pupa/refinements/faraday_middleware'

begin
  require 'multi_xml'
rescue LoadError
  # pass
end

begin
  require 'faraday-cookie_jar'
rescue LoadError
  # pass
end

module Pupa
  class Processor
    # An HTTP client factory.
    class Client
      # Returns a configured Faraday HTTP client.
      #
      # To automatically parse XML responses, you must `require 'multi_xml'`.
      #
      # Memcached support depends on the `dalli` gem.
      #
      # @param [String] cache_dir a directory or a Memcached address
      #   (e.g. `memcached://localhost:11211`) in which to cache requests
      # @param [Integer] expires_in the cache's expiration time in seconds
      # @param [Integer] value_max_bytes the maximum Memcached item size
      # @param [String] memcached_username the Memcached username
      # @param [String] memcached_password the Memcached password
      # @param [String] level the log level
      # @param [String,IO] logdev the log device
      # @param [Hash] faraday_options Faraday initialization options
      # @return [Faraday::Connection] a configured Faraday HTTP client
      def self.new(cache_dir: nil, expires_in: 86400, value_max_bytes: 1048576, memcached_username: nil, memcached_password: nil, level: 'INFO', logdev: STDOUT, faraday_options: {}) # 1 day
        follow_redirects = faraday_options.delete(:follow_redirects)

        Faraday.new(faraday_options) do |connection|
          connection.request :url_encoded
          connection.use Middleware::Logger, Logger.new('faraday', level: level)
          connection.use Faraday::Response::RaiseError

          # @see http://tools.ietf.org/html/rfc4627
          connection.use Middleware::ParseJson, preserve_raw: true, content_type: /\bjson$/

          # @see http://tools.ietf.org/html/rfc2854
          # @see http://tools.ietf.org/html/rfc3236
          if defined?(Nokogiri)
            connection.use Middleware::ParseHtml, preserve_raw: true, content_type: %w(text/html application/xhtml+xml)
          end

          # @see http://tools.ietf.org/html/rfc3023
          if defined?(MultiXml)
            connection.use FaradayMiddleware::ParseXml, preserve_raw: true, content_type: /\bxml$/
          end

          if follow_redirects
            connection.use FaradayMiddleware::FollowRedirects
          end

          if Faraday.const_defined?('CookieJar')
            connection.use Faraday::CookieJar
          end

          # Must come after the parser middlewares.
          connection.use FaradayMiddleware::Gzip

          if cache_dir
            connection.response :caching do
              address = cache_dir[%r{\Amemcached://(.+)\z}, 1]
              if address
                ActiveSupport::Cache::MemCacheStore.new(address, expires_in: expires_in, value_max_bytes: Integer(value_max_bytes), username: memcached_username, password: memcached_password)
              else
                ActiveSupport::Cache::FileStore.new(cache_dir, expires_in: expires_in)
              end
            end
          end

          if defined?(Typhoeus)
            connection.adapter :typhoeus
          else
            connection.adapter Faraday.default_adapter # must be last
          end
        end
      end
    end
  end
end
