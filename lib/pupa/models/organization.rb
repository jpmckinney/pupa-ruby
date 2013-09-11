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
  end
end
