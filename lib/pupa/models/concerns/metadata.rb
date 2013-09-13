module Pupa
  module Metadata
    extend ActiveSupport::Concern

    included do
      attr_accessor :sources, :created_at, :updated_at

      set_callback(:create, :before) do |object|
        object.created_at = Time.now.utc
      end

      set_callback(:save, :before) do |object|
        object.updated_at = Time.now.utc
      end
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
