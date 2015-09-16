require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Processor::Connection::PostgreSQLAdapter do
  include_examples 'SQL adapter', 'sqlite://pupa_test.db'
end
