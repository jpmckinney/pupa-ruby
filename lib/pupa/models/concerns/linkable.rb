module Pupa
  module Concerns
    # Adds the Popolo `links` property to a model.
    module Linkable
      extend ActiveSupport::Concern

      included do
        attr_reader :links
        dump :links
      end

      def initialize(*args)
        @links = []
        super
      end

      # Sets the links.
      #
      # @param [Array] links a list of links
      def links=(links)
        @links = symbolize_keys(links)
      end

      # Adds a URL.
      #
      # @param [String] url a URL
      # @param [String] note a note, e.g. "Wikipedia page"
      def add_link(url, note: nil)
        data = {url: url}
        if note
          data[:note] = note
        end
        if url.present?
          @links << data
        end
      end
    end
  end
end
