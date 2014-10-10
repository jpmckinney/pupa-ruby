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
      # @param [String,Date,Time] start_date the date on which the name was adopted
      # @param [String,Date,Time] end_date the date on which the name was abandoned
      # @param [String] note a note, e.g. "Birth name"
      # @param [String] family_name one or more family names
      # @param [String] given_name one or more primary given names
      # @param [String] additional_name one or more secondary given names
      # @param [String] honorific_prefix one or more honorifics preceding a person's name
      # @param [String] honorific_suffix one or more honorifics following a person's name
      # @param [String] patronymic_name one or more patronymic names
      def add_name(name, start_date: nil, end_date: nil, note: nil, family_name: nil, given_name: nil, additional_name: nil, honorific_prefix: nil, honorific_suffix: nil, patronymic_name: nil)
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
        if family_name
          data[:family_name] = family_name
        end
        if given_name
          data[:given_name] = given_name
        end
        if additional_name
          data[:additional_name] = additional_name
        end
        if honorific_prefix
          data[:honorific_prefix] = honorific_prefix
        end
        if honorific_suffix
          data[:honorific_suffix] = honorific_suffix
        end
        if patronymic_name
          data[:patronymic_name] = patronymic_name
        end
        if name.present?
          @other_names << data
        end
      end
    end
  end
end
