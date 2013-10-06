module Pupa
  module Concerns
    # Adds the Popolo `sources` property to a model.
    module Sourceable
      extend ActiveSupport::Concern

      included do
        attr_accessor :sources
        dump :sources
      end

      def initialize(*args)
        @sources = []
        super
      end

      # Adds a source to the object.
      #
      # @param [String] url a URL
      # @param [String] note a note
      def add_source(url, note: nil)
        data = {url: url}
        if note
          data[:note] = note
        end
        if url
          @sources << data
        end
      end
    end
  end
end
