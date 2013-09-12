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
  end
end
