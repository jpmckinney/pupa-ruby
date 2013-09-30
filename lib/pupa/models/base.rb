require 'pathname'
require 'securerandom'
require 'set'

require 'active_support/callbacks'
require 'active_support/core_ext/object/try'
require 'json-schema'

require 'pupa/refinements/json-schema'

JSON::Validator.cache_schemas = true

module Pupa
  # Adds methods expected by Pupa processors.
  module Model
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :create, :save

      class_attribute :json_schema
      class_attribute :properties
      class_attribute :foreign_keys
      class_attribute :foreign_objects

      self.properties = Set.new
      self.foreign_keys = Set.new
      self.foreign_objects = Set.new

      attr_reader :_id
      attr_accessor :_type, :extras

      dump :_id, :_type, :extras
    end

    module ClassMethods
      # Declare which properties should be dumped to JSON after a scraping task
      # is complete. A subset of these properties will be imported to MongoDB.
      #
      # @param [Array<Symbol>] the properties to dump to JSON
      def dump(*attributes)
        self.properties += attributes # use assignment to not overwrite the parent's attribute
      end

      # Declare the class' foreign keys.
      #
      # When importing scraped objects, the foreign keys will be used to draw a
      # dependency graph and derive an evaluation order.
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
        self.foreign_objects += attributes
      end

      # Sets the class' schema.
      #
      # @param [Hash,String] value a hash or a relative or absolute path
      def schema=(value)
        self.json_schema = if Hash === value
          value
        elsif Pathname.new(value).absolute?
          File.read(value)
        else
          File.read(File.expand_path(File.join('..', '..', '..', 'schemas', "#{value}.json"), __dir__))
        end
      end
    end

    # @param [Hash] properties the object's properties
    def initialize(properties = {})
      @_type = self.class.to_s.underscore
      @_id = SecureRandom.uuid
      @extras = {}

      properties.each do |key,value|
        self[key] = value
      end
    end

    # Returns the value of a property.
    #
    # @param [Symbol] property a property name
    # @raises [Pupa::Errors::MissingAttributeError] if class is missing the property
    def [](property)
      if properties.include?(property.to_sym)
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
      if properties.include?(property.to_sym)
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
      to_h(persist: true).except(:_id)
    end

    # Returns the object's foreign keys and foreign objects.
    #
    # @return [Hash] the object's foreign keys and foreign objects
    def foreign_properties
      to_h.slice(*foreign_keys + foreign_objects)
    end

    # Validates the object against the schema.
    #
    # @raises [JSON::Schema::ValidationError] if the object is invalid
    def validate!
      if self.class.json_schema
        # JSON::Validator#initialize_schema runs fastest if given a hash.
        JSON::Validator.validate!(self.class.json_schema, stringify_keys(to_h(persist: true)))
      end
    end

    # Returns the object as a hash.
    #
    # @param [Boolean] persist whether the object is being persisted, validated
    #   or used as a MongoDB selecto, in which case foreign objects (i.e. hints)
    #   are excluded
    # @return [Hash] the object as a hash
    def to_h(persist: false)
      {}.tap do |hash|
        (persist ? properties - foreign_objects : properties).each do |property|
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

  private

    def stringify_keys(object)
      case object
      when Hash
        {}.tap do |hash|
          object.each do |key,value|
            hash[key.to_s] = stringify_keys(value)
          end
        end
      when Array
        object.map do |value|
          stringify_keys(value)
        end
      else
        object
      end
    end
  end
end
