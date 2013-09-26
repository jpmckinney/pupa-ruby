module Pupa
  # A list of identifiers.
  class IdentifierList < Array
    # Returns the first identifier matching the scheme.
    #
    # @param [String] scheme a scheme
    # @return [String,nil] an identifier
    def find_by_scheme(scheme)
      find{|identifier|
        identifier[:scheme] == scheme
      }.try{|identifier|
        identifier[:identifier]
      }
    end
  end
end
