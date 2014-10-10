module Pupa
  module Concerns
    # Adds the Popolo `contact_details` property to a model.
    module Contactable
      extend ActiveSupport::Concern

      included do
        attr_reader :contact_details
        dump :contact_details
      end

      def initialize(*args)
        @contact_details = ContactDetailList.new
        super
      end

      # Sets the contact details.
      #
      # @param [Array] contact_details a list of contact details
      def contact_details=(contact_details)
        @contact_details = ContactDetailList.new(symbolize_keys(contact_details))
      end

      # Adds a contact detail.
      #
      # @param [String] type a type of medium, e.g. "fax" or "email"
      # @param [String] value a value, e.g. a phone number or email address
      # @param [String] note a note, e.g. for grouping contact details by physical location
      # @param [String] label a human-readable label for the contact detail
      # @param [String,Date,Time] valid_from the date from which the contact detail is valid
      # @param [String,Date,Time] valid_until the date from which the contact detail is no longer valid
      def add_contact_detail(type, value, note: nil, label: nil, valid_from: nil, valid_until: nil)
        data = {type: type, value: value}
        if note
          data[:note] = note
        end
        if label
          data[:label] = label
        end
        if valid_from
          data[:valid_from] = valid_from
        end
        if valid_until
          data[:valid_until] = valid_until
        end
        if type.present? && value.present?
          @contact_details << data
        end
      end
    end
  end
end
