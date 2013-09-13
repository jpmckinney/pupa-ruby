require 'faraday_middleware/response_middleware'

module Pupa
  module Middleware
    # @see https://github.com/lostisland/faraday_middleware/pull/18
    class ParseHtml < FaradayMiddleware::ResponseMiddleware
      dependency 'nokogiri'

      define_parser { |body|
        Nokogiri::HTML body
      }
    end
  end
end
