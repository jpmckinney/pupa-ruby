module Pupa
  module Linkable
    extend ActiveSupport::Concern

    included do
      attr_accessor :links
    end

    # Adds a URL.
    # @param [String] url a URL
    # @param [String] note a note, e.g. "Wikipedia page"
    def add_link(url, note: nil)
      data = {url: url}
      if note
        data[:note] = note
      end
      if url
        @links << data
      end
    end
  end
end
