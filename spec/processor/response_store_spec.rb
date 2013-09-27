require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::ResponseStore do
  describe '.new' do
    it 'should use the filesystem' do
      Pupa::Processor::ResponseStore::FileStore.should_receive(:new).with('/tmp').and_call_original
      Pupa::Processor::ResponseStore.new('/tmp')
    end

    it 'should use Redis' do
      Pupa::Processor::ResponseStore::RedisStore.should_receive(:new).with('localhost').and_call_original
      Pupa::Processor::ResponseStore.new('redis://localhost')
    end
  end
end
