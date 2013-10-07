module Pupa
  module Concerns
    # Adds the Popolo `other_names` property to a model.
    module Nameable
      extend ActiveSupport::Concern

      included do
        attr_reader :other_names
        dump :other_names
      end

      def initialize(*args)
        @other_names = []
        super
      end

      # Sets the other names.
      #
      # @param [Array] other_names a list of other names
      def other_names=(other_names)
        @other_names = symbolize_keys(other_names)
      end

      # Adds an alternate or former name.
      #
      # @param [String] name an alternate or former name
      # @param [Date,Time] start_date the date on which the name was adopted
      # @param [Date,Time] end_date the date on which the name was abandoned
      # @param [String] note a note, e.g. "Birth name"
      def add_name(name, start_date: nil, end_date: nil, note: nil)
        data = {name: name}
        if start_date
          data[:start_date] = start_date
        end
        if end_date
          data[:end_date] = end_date
        end
        if note
          data[:note] = note
        end
        if name.present?
          @other_names << data
        end
      end
    end
  end
end
