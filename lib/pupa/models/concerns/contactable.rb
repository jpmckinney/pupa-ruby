module Pupa
  module Contactable
    extend ActiveSupport::Concern

    included do
      attr_accessor :contact_details
    end

    # Sets the contact details.
    #
    # @param [Array] contact_details a list of contact details
    def contact_details=(contact_details)
      @contact_details = ContactDetailList.new(contact_details)
    end

    # Adds a contact detail.
    #
    # @param [String] type a type of medium, e.g. "fax" or "email"
    # @param [String] value a value, e.g. a phone number or email address
    # @param [String] note a note, e.g. for grouping contact details by physical location
    def add_contact_detail(type, value, note: nil)
      data = {type: type, value: value}
      if note
        data[:note] = note
      end
      if type && value
        (@contact_details ||= ContactDetailList.new) << data
      end
    end
  end
end
