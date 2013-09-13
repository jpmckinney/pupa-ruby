require 'active_support/cache'
require 'faraday_middleware'

require 'pupa/processor/middleware/parse_html'

module Pupa
  class Processor
    # A refinement for the Faraday caching middleware to cache all requests, not
    # only GET requests.
    module CacheAllRequests
      refine FaradayMiddleware::Caching do
        def call(env)
          # Remove if-statement to cache any request, not only GET.
          if env[:parallel_manager]
            # callback mode
            cache_on_complete(env)
          else
            # synchronous mode
            response = cache.fetch(cache_key(env)) { @app.call(env) }
            finalize_response(response, env)
          end
        end

        def cache_key(env)
          url = env[:url].dup
          if url.query && params_to_ignore.any?
            params = parse_query url.query
            params.reject! {|k,| params_to_ignore.include? k }
            url.query = build_query params
          end
          url.normalize!
          url.request_uri + env[:body].to_s # Add for POST requests.
        end
      end
    end

    # An HTTP client factory.
    class Client
      using CacheAllRequests

      # Returns a configured Faraday HTTP client.
      #
      # @param [String] cache_dir a directory in which to cache requests
      # @param [Integer] expires_in the cache's expiration time in seconds
      # @return [Faraday::Connection] a configured Faraday HTTP client
      def self.new(cache_dir: nil, expires_in: 86400) # 1 day
        Faraday.new do |connection|
          connection.response :logger, Logger.new('faraday')
          # @see http://tools.ietf.org/html/rfc2854
          # @see http://tools.ietf.org/html/rfc3236
          connection.use Pupa::Processor::Middleware::ParseHtml, content_type: %w(text/html application/xhtml+xml)
          # @see http://tools.ietf.org/html/rfc4627
          connection.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
          # @see http://tools.ietf.org/html/rfc3023
          connection.use FaradayMiddleware::ParseXml, content_type: /\bxml$/
          if cache_dir
            connection.response :caching do
              ActiveSupport::Cache::FileStore.new(cache_dir, expires_in: expires_in)
            end
          end
          connection.adapter Faraday.default_adapter # must be last
        end
      end
    end
  end
end
