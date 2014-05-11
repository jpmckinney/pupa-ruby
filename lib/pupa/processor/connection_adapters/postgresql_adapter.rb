require 'pg'

module Pupa
  class Processor
    class Connection
      # A proxy class to save plain old Ruby objects to PostgreSQL.
      class PostgreSQLAdapter
        attr_reader :raw_connection

        # @param [String] host_with_port the host and port to the database system
        # @param [String] database the name of the database
        def initialize(host_with_port, database: 'pupa', **options)
          host, port = host_with_port.split(':', 2)
          args = {host: host, port: port || 5432, dbname: database}

          if options.key?(:username)
            args[:user] = options[:username]
          end
          if options.key?(:password)
            args[:password] = options[:password]
          end

          @raw_connection = PG.connect(args)
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
