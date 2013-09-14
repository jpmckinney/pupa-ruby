module Pupa
  class Processor
    module Middleware
      # Customizes the Faraday default logger.
      class Logger < FaradayMiddleware::ResponseMiddleware
        extend Forwardable

        def initialize(app, logger = nil)
          super(app)
          @logger = logger || begin
            require 'logger'
            ::Logger.new(STDOUT)
          end
        end

        def_delegators :@logger, :debug, :info, :warn, :error, :fatal

        def call(env)
          info "#{env[:method]} #{env[:url].to_s} #{env[:body].to_s}" # add POST body
          debug('request') { dump_headers env[:request_headers] }
          super
        end

        def on_complete(env)
          debug('Status') { env[:status].to_s } # switch from info
          debug('response') { dump_headers env[:response_headers] }
        end

        private

        def dump_headers(headers)
          headers.map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
        end
      end
    end
  end
end
