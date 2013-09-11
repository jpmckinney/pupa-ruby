require 'active_support/cache'
require 'faraday_middleware'

require 'faraday_middleware_ext/caching'
require 'pupa/middleware/parse_html'

using FaradayMiddewareExt

module Pupa
  class Client
    # Returns a configured Faraday HTTP client.
    #
    # @param [String] cache_dir a directory in which to cache requests
    # @return [Faraday::Connection] a configured Faraday HTTP client
    def self.new(cache_dir)
      Faraday.new do |connection|
        connection.response :logger, Logger.new('faraday')
        # @see http://tools.ietf.org/html/rfc2854
        # @see http://tools.ietf.org/html/rfc3236
        connection.use Pupa::Middleware::ParseHtml, content_type: %w(text/html application/xhtml+xml)
        # @see http://tools.ietf.org/html/rfc4627
        connection.use FaradayMiddleware::ParseJson, content_type: /\bjson$/
        # @see http://tools.ietf.org/html/rfc3023
        connection.use FaradayMiddleware::ParseXml, content_type: /\bxml$/
        connection.response :caching do
          ActiveSupport::Cache::FileStore.new(cache_dir, expires_in: 86400) # 1 day
        end
        connection.adapter Faraday.default_adapter # must be last
      end
    end
  end
end
