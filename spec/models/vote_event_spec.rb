require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::VoteEvent do
  let :object do
    Pupa::VoteEvent.new(identifier: '1', organization_id: 'legislative-council-of-hong-kong')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == '1 in legislative-council-of-hong-kong'
    end
  end
end
