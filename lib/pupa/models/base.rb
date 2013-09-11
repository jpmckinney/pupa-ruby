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

      def schema=(fragment)
        @schema = File.expand_path(File.join('..', '..', 'schemas', "#{fragment}.json"), __dir__)
      end

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

    attr_accessor :id, :sources, :extras, :created_at, :updated_at

    # @param [Hash] kwargs the object's attributes
    def initialize(**kwargs)
      @id = SecureRandom.uuid
      @sources = []
      @extras = {}

      kwargs.each do |key,value|
        send(key, value)
      end
    end

    # Validates an object against a schema.
    #
    # @param [Object] an object
    def validate!(object)
      if self.class.schema
        JSON::Validator.validate!(self.class.schema, object.to_h)
      end
    end

    # Adds a source to the object.
    #
    # @param [String] url a URL
    # @param [String] note a note
    def add_source(url, note: nil)
      data = {url: url}
      if note
        data[:note] = note
      end
      if url
        @sources << data
      end
    end

    # Adds a key-value pair to the object.
    #
    # @param [Symbol] key a key
    # @param value a value
    def add_extra(key, value)
      @extras[key] = value
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
