require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::DocumentStore do
  describe '.new' do
    it 'should use the filesystem' do
      expect(Pupa::Processor::DocumentStore::FileStore).to receive(:new).with('/tmp').and_call_original
      Pupa::Processor::DocumentStore.new('/tmp')
    end

    it 'should use Redis' do
      expect(Pupa::Processor::DocumentStore::RedisStore).to receive(:new).with('redis://localhost', {}).and_call_original
      Pupa::Processor::DocumentStore.new('redis://localhost')
    end
  end
end
