module Pupa
  # A real person, alive or dead.
  class Person < Base
    self.schema = 'popolo/person'

    include Nameable
    include Identifiable
    include Contactable
    include Linkable

    attr_accessor :name, :family_name, :given_name, :additional_name,
      :honorific_prefix, :honorific_suffix, :patronymic_name, :sort_name,
      :email, :gender, :birth_date, :death_date, :image, :summary, :biography

    def initialize(**kwargs)
      @other_names     = []
      @identifiers     = []
      @contact_details = ContactDetailList.new
      @links           = []
      super
    end

  # Returns the person's name.
  #
  # @return [String] the person's name
  def to_s
    name
  end
end
