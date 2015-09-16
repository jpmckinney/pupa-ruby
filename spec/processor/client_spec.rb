require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::Client do
  describe '.new' do
    it 'should use the filesystem' do
      ActiveSupport::Cache::FileStore.should_receive(:new).and_call_original
      Pupa::Processor::Client.new(cache_dir: '/tmp', level: 'UNKNOWN').get('http://httpbin.org/')
    end

    it 'should use Memcached' do
      ActiveSupport::Cache::MemCacheStore.should_receive(:new).and_call_original
      Pupa::Processor::Client.new(cache_dir: 'memcached://localhost', level: 'UNKNOWN').get('http://httpbin.org/')
    end
  end
end
