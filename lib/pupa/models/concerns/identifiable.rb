module Pupa
  module Concerns
    # Adds the Popolo `identifiers` property to a model.
    module Identifiable
      extend ActiveSupport::Concern

      included do
        attr_accessor :identifiers
      end

      # Adds an issued identifier.
      #
      # @param [String] identifier an issued identifier, e.g. a DUNS number
      # @param [String] scheme an identifier scheme, e.g. DUNS
      def add_identifier(identifier, scheme: nil)
        data = {identifier: identifier}
        if scheme
          data[:scheme] = scheme
        end
        if identifier
          (@identifiers ||= []) << data
        end
      end
    end
  end
end
