module Pupa
  module Metadata
    extend ActiveSupport::Concern

    included do
      attr_accessor :sources, :created_at, :updated_at
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
        (@sources ||= []) << data
      end
    end
  end
end
