module Pupa
  # A group with a common purpose or reason for existence that goes beyond the set
  # of people belonging to it.
  class Organization < Base
    self.schema = 'popolo/organization'

    include Nameable
    include Identifiable
    include Contactable
    include Linkable

    attr_accessor :name, :classification, :parent_id, :founding_date,
      :dissolution_date, :image

    def initialize(**kwargs)
      @other_names     = []
      @identifiers     = []
      @contact_details = ContactDetailList.new
      @links           = []
      super
    end

    # Returns the name of the organization.
    #
    # @return [String] the name of the organization
    def to_s
      name
    end

    # Sets the ID of the organization that contains this organization.
    #
    # @param [String] parent the ID of the organization that contains this organization
    def parent=(parent)
      self.parent_id = parent.id
    end

    # Returns the ID of the organization that contains this organization.
    # @return [String] the ID of the organization that contains this organization
    def parent
      parent_id
    end
  end
end
