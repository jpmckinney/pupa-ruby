module Pupa
  # A relationship between a person and an organization.
  class Membership < Base
    self.schema = 'popolo/membership'

    include Metadata
    include Contactable
    include Linkable

    attr_accessor :label, :role, :person_id, :organization_id, :post_id,
      :start_date, :end_date

    foreign_keys :person_id, :organization_id, :post_id

    # Returns the IDs of the parties to the relationship.
    #
    # @return [String] the IDs of the parties to the relationship
    def to_s
      "#{person_id} in #{organization_id}"
    end

    # A person's relationship with an organization must have a unique label,
    # though it may share a label with a historical relationship. Similarly, a
    # person may hold a post in an organization multiple times historically but
    # not simultaneously.
    def fingerprint
      hash = to_h
      {
        '$or': [
          hash.slice(:label, :person_id, :organization_id, :end_date),
          hash.slice(:person_id, :organization_id, :post_id, :end_date),
        ],
      }
    end
  end
end
