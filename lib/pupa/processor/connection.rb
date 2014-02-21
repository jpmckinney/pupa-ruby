module Pupa
  class Processor
    # A database system connection factory.
    class Connection
      # Returns a configured connection to a database system.
      #
      # See each connection adapter for more information.
      #
      # @param [String] adapter the database system adapter
      # @param [String] host_with_port the host and port to the database system
      # @param [Hash] options optional arguments
      # @return a configured connection to a database system
      def self.new(adapter, host_with_port, **options)
        case adapter
        when 'postgresql'
          raise NotImplementedError
        else
          MongoDBAdapter.new(host_with_port, options)
        end
      end
    end
  end
end
