module Pupa
  # A list of contact details.
  class ContactDetailList < Array
    # Returns the first postal address within the list of contact details.
    #
    # @return [String,nil] a postal address
    def address
      find_by_type('address')
    end

    # Returns the first email address within the list of contact details.
    #
    # @return [String,nil] an email address
    def email
      find_by_type('email')
    end

    # Returns the value of the first contact detail matching the type.
    #
    # @param [String] a type
    # @return [String,nil] a value
    def find_by_type(type)
      find{|contact_detail|
        contact_detail[:type] == type
      }.try{|contact_detail|
        contact_detail[:value]
      }
    end
  end
end
