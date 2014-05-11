require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::Connection do
  describe '.new' do
    it 'should use MongoDB' do
      Pupa::Processor::Connection::MongoDBAdapter.should_receive(:new).with('mongodb://localhost:27017/pupa').and_call_original
      Pupa::Processor::Connection.new('mongodb://localhost:27017/pupa')
    end

    it 'should use PostgreSQL' do
      Pupa::Processor::Connection::PostgreSQLAdapter.should_receive(:new).with('postgres://localhost:5432/pupa').and_call_original
      Pupa::Processor::Connection.new('postgres://localhost:5432/pupa')
    end
  end
end
