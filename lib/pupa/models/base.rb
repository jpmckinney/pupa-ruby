require 'pathname'
require 'securerandom'
require 'set'

require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'json-schema'

module Pupa
  # The base class from which other primary Popolo classes inherit.
  class Base
    class_attribute :properties
    self.properties = Set.new

    class << self
      def attr_accessor(*attributes)
        self.properties += attributes # use assignment to not overwrite the parent's attribute
        super
      end

      # Sets the path to the class' schema.
      #
      # @param [String] path a relative or absolute path
      def schema=(path)
        @schema = if Pathname.new(path).absolute?
          path
        else
          File.expand_path(File.join('..', '..', '..', 'schemas', "#{path}.json"), __dir__)
        end
      end

      # Returns the absolute path to the class' schema.
      #
      # @return [String] the absolute path to the class' schema
      def schema
        @schema
      end

      # Converts a hash into an object.
      #
      # @param [Hash] hash an object as a hash
      # @return [Object] an object
      def from_h(hash)
        new(hash)
      end
    end

    attr_accessor :id, :extras

    # @param [Hash] kwargs the object's attributes
    def initialize(**kwargs)
      @id = SecureRandom.uuid
      @extras = {}

      kwargs.each do |key,value|
        send(key, value)
      end
    end

    # Adds a key-value pair to the object.
    #
    # @param [Symbol] key a key
    # @param value a value
    def add_extra(key, value)
      @extras[key] = value
    end

    # Validates an object against a schema.
    #
    # @param [Object] an object
    def validate!(object)
      if self.class.schema
        JSON::Validator.validate!(self.class.schema, object.to_h)
      end
    end

    # Returns the object as a hash.
    #
    # @return [Hash] the object as a hash
    def to_h
      {}.tap do |hash|
        properties.each do |property|
          value = send(property)
          if value == false || value.present?
            hash[property] = value
          end
        end
      end
    end

    # Returns whether two objects are identical, ignoring any differences in
    # the objects' machine IDs.
    #
    # @param [Object] other another object
    # @return [Boolean] whether the objects are identical
    def ==(other)
      a = to_h
      b = other.to_h
      a.delete(:id)
      b.delete(:id)
      a == b
    end
  end
end
