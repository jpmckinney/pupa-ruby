require 'active_support/cache'
require 'faraday_middleware'
require 'faraday_middleware/response_middleware'

require 'pupa/processor/middleware/logger'
require 'pupa/processor/middleware/parse_html'
require 'pupa/refinements/faraday_middleware'

begin
  require 'multi_xml'
rescue LoadError
  # pass
end

module Pupa
  class Processor
    # An HTTP client factory.
    class Client
      # Returns a configured Faraday HTTP client.
      #
      # @param [String] cache_dir a directory in which to cache requests
      # @param [Integer] expires_in the cache's expiration time in seconds
      # @param [String] level the log level
      # @return [Faraday::Connection] a configured Faraday HTTP client
      def self.new(cache_dir: nil, expires_in: 86400, level: 'INFO') # 1 day
        Faraday.new do |connection|
          connection.request :url_encoded
          connection.use Middleware::Logger, Logger.new('faraday', level: level)
          # @see http://tools.ietf.org/html/rfc2854
          # @see http://tools.ietf.org/html/rfc3236
          connection.use Middleware::ParseHtml, content_type: %w(text/html application/xhtml+xml)
          # @see http://tools.ietf.org/html/rfc4627
          connection.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
          # @see http://tools.ietf.org/html/rfc3023
          if defined?(MultiXml)
            connection.use FaradayMiddleware::ParseXml, content_type: /\bxml$/
          end
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
