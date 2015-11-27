module Pupa
  # A position that exists independent of the person holding it.
  class Post
    include Model

    self.schema = 'schemas/popolo/post.json'

    include Concerns::Timestamps
    include Concerns::Sourceable
    include Concerns::Contactable
    include Concerns::Linkable

    attr_accessor :label, :other_label, :role, :organization_id, :area_id, :start_date, :end_date
    dump          :label, :other_label, :role, :organization_id, :area_id, :start_date, :end_date

    foreign_key :organization_id, :area_id

    # Returns the post's label or role and organization ID.
    #
    # @return [String] the post's label or role and organization ID
    def to_s
      "#{label || role} in #{organization_id}"
    end

    # A post should have a unique label within an organization, through it may
    # share a label with a historical post.
    def fingerprint
      super.slice(:label, :organization_id, :end_date)
    end
  end
end
