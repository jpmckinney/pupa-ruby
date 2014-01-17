module Pupa
  module Refinements
    # Faraday requires `params` to be a hash.
    module Connection
      # @see https://github.com/lostisland/faraday/blob/b8d90a59bafb8dd6e19488fae07945a7700f5664/lib/faraday/connection.rb#L137
      def get(url=nil, params=nil, headers=nil, &block)
        if String === params
          params = CGI.parse(params)

          # Flatten the parameters for Faraday.
          params.each do |key,value|
            if Array === value && value.size == 1
              params[key] = value.first
            end
          end
        end

        super(url, params, headers, &block)
      end
    end
  end
end

class Faraday::Connection
  prepend Pupa::Refinements::Connection
end
