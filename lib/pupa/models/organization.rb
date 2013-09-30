module Pupa
  # A group with a common purpose or reason for existence that goes beyond the set
  # of people belonging to it.
  class Organization
    include Model

    self.schema = 'popolo/organization'

    include Concerns::Timestamps
    include Concerns::Sourceable
    include Concerns::Nameable
    include Concerns::Identifiable
    include Concerns::Contactable
    include Concerns::Linkable

    attr_accessor :name, :classification, :parent_id, :parent, :founding_date,
      :dissolution_date, :image
    dump :name, :classification, :parent_id, :parent, :founding_date,
      :dissolution_date, :image

    foreign_key :parent_id

    foreign_object :parent

    # Returns the name of the organization.
    #
    # @return [String] the name of the organization
    def to_s
      name
    end

    # @todo Parentless organizations in different jurisdictions can have the
    #   same name. Add a `jurisdiction` property?
    def fingerprint
      hash = super.slice(:classification, :parent_id)
      {
        '$or' => [
          hash.merge('name' => name),
          hash.merge('other_names.name' => name),
        ],
      }
    end
  end
end
