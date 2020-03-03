require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::Connection do
  describe '.new' do
    it 'should use MongoDB' do
      expect(Pupa::Processor::Connection::MongoDBAdapter).to receive(:new).with('mongodb://localhost:27017/pupa_test').and_call_original
      Pupa::Processor::Connection.new('mongodb://localhost:27017/pupa_test')
    end

    it 'should use PostgreSQL' do
      expect(Pupa::Processor::Connection::PostgreSQLAdapter).to receive(:new).with('postgres://localhost:5432/pupa_test').and_call_original
      Pupa::Processor::Connection.new('postgres://localhost:5432/pupa_test')
    end
  end
end
