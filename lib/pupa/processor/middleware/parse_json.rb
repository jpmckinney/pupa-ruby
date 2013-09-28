module Pupa
  class Processor
    module Middleware
      # A Faraday response middleware for parsing JSON.
      #
      # @see https://github.com/lostisland/faraday_middleware/issues/30#issuecomment-4706892
      class ParseJson < FaradayMiddleware::ResponseMiddleware
        dependency 'multi_json'

        define_parser do |body|
          MultiJson.load(body) unless body.strip.empty?
        end
      end
    end
  end
end
