module Pupa
  # A group with a common purpose or reason for existence that goes beyond the set
  # of people belonging to it.
  class Organization
    include Model

    self.schema = File.expand_path(File.join('..', '..', '..', 'schemas', 'popolo', 'organization.json'), __dir__)

    include Concerns::Timestamps
    include Concerns::Sourceable
    include Concerns::Nameable
    include Concerns::Identifiable
    include Concerns::Contactable
    include Concerns::Linkable

    attr_accessor :name, :classification, :parent_id, :area_id, :founding_date, :dissolution_date, :image, :parent
    dump          :name, :classification, :parent_id, :area_id, :founding_date, :dissolution_date, :image, :parent

    foreign_key :parent_id, :area_id

    foreign_object :parent # for testing

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
      if name
        {
          '$or' => [
            hash.merge('name' => name),
            hash.merge('other_names.name' => name),
          ],
        }
      else
        hash
      end
    end
  end
end
