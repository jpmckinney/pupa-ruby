module Pupa
  # A group with a common purpose or reason for existence that goes beyond the set
  # of people belonging to it.
  class Organization < Base
    self.schema = 'popolo/organization'

    include Metadata
    include Nameable
    include Identifiable
    include Contactable
    include Linkable

    attr_accessor :name, :classification, :parent_id, :founding_date,
      :dissolution_date, :image

    foreign_keys :parent_id

    # Returns the name of the organization.
    #
    # @return [String] the name of the organization
    def to_s
      name
    end

    # @todo Parentless organizations in different jurisdictions can have the
    #   same name. Add a `jurisdiction` property?
    def fingerprint
      hash = to_h.slice(:classification, :parent_id)
      {
        '$or' => [
          hash.merge('name' => name),
          hash.merge('other_names.name' => name),
        ],
      }
    end

    # Sets the ID of the organization that contains this organization.
    #
    # @param [String] parent the ID of the organization that contains this organization
    def parent=(parent)
      self.parent_id = parent._id
    end

    # Returns the ID of the organization that contains this organization.
    # @return [String] the ID of the organization that contains this organization
    def parent
      parent_id
    end
  end
end
