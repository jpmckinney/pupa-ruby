module Pupa
  module Concerns
    # Adds private methods for changing hash keys to strings or symbols.
    module IndifferentAccess
      extend ActiveSupport::Concern

      private

      def transform_keys(object, meth)
        case object
        when Hash
          {}.tap do |hash|
            object.each do |key,value|
              hash[key.send(meth)] = transform_keys(value, meth)
            end
          end
        when Array
          object.map do |value|
            transform_keys(value, meth)
          end
        else
          object
        end
      end

      def symbolize_keys(object)
        transform_keys(object, :to_sym)
      end

      def stringify_keys(object)
        transform_keys(object, :to_s)
      end
    end
  end
end
