module Pupa
  # A relationship between a person and an organization.
  class Membership
    include Model

    self.schema = File.expand_path(File.join('..', '..', '..', 'schemas', 'popolo', 'membership.json'), __dir__)

    include Concerns::Timestamps
    include Concerns::Sourceable
    include Concerns::Contactable
    include Concerns::Linkable

    attr_accessor :label, :role, :member, :person_id, :organization_id, :post_id, :on_behalf_of_id, :area_id, :start_date, :end_date
    dump          :label, :role, :member, :person_id, :organization_id, :post_id, :on_behalf_of_id, :area_id, :start_date, :end_date

    foreign_key :person_id, :organization_id, :post_id, :on_behalf_of_id, :area_id

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
      hash = super
      {
        '$or' => [
          hash.slice(:label, :person_id, :organization_id, :end_date),
          hash.slice(:person_id, :organization_id, :post_id, :end_date),
        ],
      }
    end
  end
end
