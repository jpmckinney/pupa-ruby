require 'sequel'

module Pupa
  class Processor
    class Connection
      # A proxy class to save plain old Ruby objects to PostgreSQL.
      class PostgreSQLAdapter
        attr_reader :raw_connection

        # @param [String] database_url the database URL
        def initialize(database_url)
          @raw_connection = Sequel.connect(database_url)
        end

        # Finds a document matching the selection criteria.
        #
        # The selection criteria *must* set a `_type` key in order to determine
        # the table to query.
        #
        # @param [Hash] selector the selection criteria
        # @return [Hash,nil] the matched document, or nil
        # @raises [Pupa::Errors::TooManyMatches] if multiple documents are found
        def find(selector)
          raise NotImplementedError
        end

        # Inserts or replaces a document in PostgreSQL.
        #
        # @param [Object] object an object
        # @return [Array] whether the object was inserted and the object's database ID
        # @raises [Pupa::Errors::TooManyMatches] if multiple documents would be updated
        def save(object)
          raise NotImplementedError
        end

        # Returns all objects within a table.
        #
        # @param [String,Symbol] the name of the table
        # @return [Array<Hash>] all objects within the table
        def find_all(table_name)
          raise NotImplementedError
        end

        # Drops a table from the PostgreSQL database.
        def drop(table_name)
          raise NotImplementedError
        end
      end
    end
  end
end
