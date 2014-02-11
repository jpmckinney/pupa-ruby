module Pupa
  class Processor
    module Middleware
      # A Faraday response middleware for raising an error if unsuccessful.
      #
      # @see Faraday::Response::RaiseError
      # @note Faraday has no tests for this middleware.
      class RaiseError < Faraday::Response::Middleware
        def on_complete(env)
          case env[:status]
          when 404
            raise Faraday::Error::ResourceNotFound, response_values(env)
          when 407
            # mimic the behavior that we get with proxy requests with HTTPS
            raise Faraday::Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
          when 400...600
            raise Faraday::Error::ClientError, response_values(env)
          end
        end

        def response_values(env) # XXX add more keys
          {
            method: env[:method],
            url: env[:url].to_s,
            request_headers: env[:request_headers],
            status: env[:status],
            response_headers: env[:response_headers],
            body: env[:body].to_s,
          }
        end
      end
    end
  end
end
