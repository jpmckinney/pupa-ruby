module Pupa
  class Processor
    module Middleware
      # A Faraday response middleware for parsing HTML.
      #
      # @see https://github.com/lostisland/faraday_middleware/pull/18
      class ParseHtml < FaradayMiddleware::ResponseMiddleware
        dependency 'nokogiri'

        define_parser { |body|
          Nokogiri::HTML(body) unless body.empty?
        }
      end
    end
  end
end
