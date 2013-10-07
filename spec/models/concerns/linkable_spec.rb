require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Linkable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Linkable
    end
  end

  let :object do
    klass.new
  end

  describe '#links' do
    it 'should symbolize keys' do
      object.links = [{'url' => 'http://example.com', 'note' => 'homepage'}]
      object.links.should == [{url: 'http://example.com', note: 'homepage'}]
    end
  end

  describe '#add_link' do
    it 'should add a link' do
      object.add_link('http://example.com', note: 'homepage')
      object.links.should == [{url: 'http://example.com', note: 'homepage'}]
    end

    it 'should not add a link without a url' do
      object.add_link(nil)
      object.add_link('')
      object.links.blank?.should == true
    end
  end
end
