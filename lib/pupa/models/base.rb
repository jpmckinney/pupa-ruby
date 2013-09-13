require 'pathname'
require 'securerandom'
require 'set'

require 'active_support/callbacks'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/try'
require 'json-schema'

module Pupa
  # The base class from which other primary Popolo classes inherit.
  class Base
    include ActiveSupport::Callbacks
    define_callbacks :create, :save

    class_attribute :schema
    class_attribute :properties
    class_attribute :foreign_keys
    class_attribute :foreign_objects

    self.properties = Set.new
    self.foreign_keys = Set.new
    self.foreign_objects = Set.new

    class << self
      # Declare the class' properties.
      #
      # When converting an object to a hash using the `to_h` method, only the
      # properties declared with `attr_accessor` will be included in the hash.
      #
      # @param [Array<Symbol>] the class' properties
      def attr_accessor(*attributes)
        self.properties += attributes # use assignment to not overwrite the parent's attribute
        super
      end

      # Declare the class' foreign keys.
      #
      # When loading extracted objects, the foreign keys will be used to draw
      # a dependency graph and derive an evaluation order.
      #
      # @param [Array<Symbol>] the class' foreign keys
      def foreign_key(*attributes)
        self.foreign_keys += attributes
      end

      # Declare the class' foreign objects.
      #
      # If some cases, you may not know the ID of an existing foreign object,
      # but you may have other information to identify the object. In that case,
      # put the information you have in a property named after the foreign key
      # without the `_id` suffix: for example, `person` for `person_id`. Before
      # saving the object to the database, Pupa.rb will use this information to
      # identify the foreign object.
      #
      # @param [Array<Symbol>] the class' foreign objects
      def foreign_object(*attributes)
        self.foreign_object += attributes
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
    end

    attr_accessor :_id, :_type, :extras

    # @param [Hash] kwargs the object's attributes
    def initialize(**kwargs)
      @_type = self.class.to_s.underscore
      @_id = "ocd-#{self.class.to_s.demodulize.underscore}/#{SecureRandom.uuid}"
      @extras = {}

      kwargs.each do |key,value|
        self[key] = value
      end
    end

    # Returns the value of a property.
    #
    # @param [Symbol] property a property name
    # @raises [Pupa::Errors::MissingAttributeError] if class is missing the property
    def [](property)
      if properties.include?(property)
        send(property)
      else
        raise Errors::MissingAttributeError, "missing attribute: #{property}"
      end
    end

    # Sets the value of a property.
    #
    # @param [Symbol] property a property name
    # @param value a value
    # @raises [Pupa::Errors::MissingAttributeError] if class is missing the property
    def []=(property, value)
      if properties.include?(property)
        send("#{property}=", value)
      else
        raise Errors::MissingAttributeError, "missing attribute: #{property}"
      end
    end

    # Sets the object's ID.
    #
    # @param [String,Moped::BSON::ObjectId] id an ID
    def _id=(id)
      @_id = id.to_s # in case of Moped::BSON::ObjectId
    end

    # Adds a key-value pair to the object.
    #
    # @param [Symbol] key a key
    # @param value a value
    def add_extra(key, value)
      @extras[key] = value
    end

    # Returns a subset of the object's properties that should uniquely identify
    # the object.
    #
    # @return [Hash] a subset of the object's properties
    def fingerprint
      to_h
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
        (properties - foreign_objects).each do |property|
          value = self[property]
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
      a.delete(:_id)
      b.delete(:_id)
      a == b
    end
  end
end
