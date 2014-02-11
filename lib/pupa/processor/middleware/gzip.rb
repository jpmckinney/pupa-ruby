module Pupa
  class Processor
    module Middleware
      # A Faraday response middleware for parsing gzip responses.
      #
      # @see https://gist.github.com/romanbsd/3892387
      class Gzip < Faraday::Response::Middleware
        dependency 'zlib'

        def on_complete(env)
          encoding = env[:response_headers]['content-encoding'].to_s.downcase
          case encoding
          when 'gzip'
            env[:body] = Zlib::GzipReader.new(StringIO.new(env[:body]), encoding: 'ASCII-8BIT').read
            env[:response_headers].delete('content-encoding')
          when 'deflate'
            env[:body] = Zlib::Inflate.inflate(env[:body])
            env[:response_headers].delete('content-encoding')
          end
        end
      end
    end
  end
end
