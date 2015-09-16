require 'pupa/processor/connection_adapters/mongodb_adapter'
require 'pupa/processor/connection_adapters/postgresql_adapter'

module Pupa
  class Processor
    # A database system connection factory.
    class Connection
      # Returns a configured connection to a database system.
      #
      # See each connection adapter for more information.
      #
      # @param [String] database_url the database URL
      # @return a configured connection to a database system
      def self.new(database_url)
        case URI.parse(database_url).scheme
        when 'postgres', 'sqlite'
          PostgreSQLAdapter.new(database_url)
        when 'mongodb'
          MongoDBAdapter.new(database_url)
        else
          raise NotImplementedError
        end
      end
    end
  end
end
