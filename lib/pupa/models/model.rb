require 'pathname'
require 'securerandom'
require 'set'

require 'active_support/callbacks'
require 'active_support/core_ext/object/try'
require 'json-schema'

module Pupa
  # Adds methods expected by Pupa processors.
  module Model
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      include Concerns::IndifferentAccess

      define_callbacks :create, :save

      class_attribute :json_schema
      class_attribute :validator
      class_attribute :properties
      class_attribute :foreign_keys
      class_attribute :foreign_objects

      self.properties = Set.new
      self.foreign_keys = Set.new
      self.foreign_objects = Set.new

      # @return [String] The object's unique identifier.
      attr_reader :_id
      # @return [Hash] The object's non-schema properties.
      attr_reader :extras
      # @return [String] The underscored, lowercase form of the object's class.
      attr_accessor :_type
      # @return [BSON::Document,nil] The object's matching document in
      #   the database. Set before persisting the object to the database.
      attr_accessor :document

      dump :_id, :_type, :extras
    end

    module ClassMethods
      # Declare which properties should be dumped to JSON after a scraping task
      # is complete. A subset of these will be imported to the database.
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
      # @note `JSON::Validator#initialize_schema` runs fastest if given a hash.
      def schema=(value)
        self.json_schema = value
        self.validator = JSON::Validator.new(self.json_schema, {}, {
          clear_cache: false,
          parse_data: false,
        })
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
    # @param [String,BSON::ObjectId] id an ID
    def _id=(id)
      @_id = id.to_s # in case of BSON::ObjectId
    end

    # Sets the extras.
    #
    # @param [Array] extras a list of extras
    def extras=(extras)
      @extras = symbolize_keys(extras)
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
        self.class.validator.instance_variable_set('@errors', [])
        self.class.validator.instance_variable_set('@data', stringify_keys(to_h(persist: true)))
        self.class.validator.validate
        true
      end
    end

    # Returns the object as a hash.
    #
    # @param [Boolean] persist whether the object is being persisted, validated,
    #   or used as a database selector, in which case foreign objects (hints)
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
  end
end
