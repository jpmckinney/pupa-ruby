require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Motion do
  let :object do
    Pupa::Motion.new(text: 'That the Bill is to be read a second time.', organization_id: 'house-of-commons')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == 'That the Bill is to be read a second time. in house-of-commons'
    end
  end
end
