require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Sourceable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Sourceable
    end
  end

  let :object do
    klass.new
  end

  describe '#add_source' do
    it 'should add a source' do
      object.add_source('http://example.com', note: 'homepage')
      object.sources.should == [{url: 'http://example.com', note: 'homepage'}]
    end

    it 'should not add a source without a url' do
      object.add_source(nil)
      object.sources.blank?.should == true
    end
  end
end
