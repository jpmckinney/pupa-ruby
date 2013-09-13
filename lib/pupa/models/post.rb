module Pupa
  class Post < Base
    self.schema = 'popolo/post'

    include Metadata
    include Contactable
    include Linkable

    attr_accessor :label, :role, :organization_id, :start_date, :end_date

    foreign_keys :organization_id

    # Returns the post's label and organization ID.
    #
    # @return [String] the post's label and organization ID
    def to_s
      "#{label} in #{organization_id}"
    end

    # A post should have a unique label within an organization, through it may
    # share a label with a historical post.
    def fingerprint
      to_h.slice(:label, :organization_id, :end_date)
    end
  end
end
