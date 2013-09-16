module Pupa
  # A real person, alive or dead.
  class Person < Base
    self.schema = 'popolo/person'

    include Concerns::Timestamps
    include Concerns::Sourceable
    include Concerns::Nameable
    include Concerns::Identifiable
    include Concerns::Contactable
    include Concerns::Linkable

    attr_accessor :name, :family_name, :given_name, :additional_name,
      :honorific_prefix, :honorific_suffix, :patronymic_name, :sort_name,
      :email, :gender, :birth_date, :death_date, :image, :summary, :biography

    # Returns the person's name.
    #
    # @return [String] the person's name
    def to_s
      name
    end

    # @todo This will obviously need to be scoped as in Python Pupa, to a
    #  jurisdiction, post, etc.
    def fingerprint
      {
        '$or' => [
          {'name' => name},
          {'other_names.name' => name},
        ],
      }
    end
  end
end
