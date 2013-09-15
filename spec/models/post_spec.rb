require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Post do
  let :object do
    Pupa::Post.new(label: 'Chef', organization_id: 'abc-inc', end_date: '2010')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == 'Chef in abc-inc'
    end
  end

  describe '#fingerprint' do
    it 'should return the fingerprint' do
      object.fingerprint.should == {label: 'Chef', organization_id: 'abc-inc', end_date: '2010'}
    end
  end
end
