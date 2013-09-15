require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::ContactDetailList do
  let :object do
    Pupa::ContactDetailList.new([
      {
        type: 'address',
        value: 'first',
      },
      {
        type: 'address',
        value: 'second',
      },
      {
        type: 'email',
        value: 'first',
      },
      {
        type: 'email',
        value: 'second',
      },
    ])
  end

  describe '#address' do
    it 'should return the first postal address' do
      object.address.should == 'first'
    end

    it 'should return nil if no postal addresses' do
      Pupa::ContactDetailList.new.address.should == nil
    end
  end

  describe '#email' do
    it 'should return the first email address' do
      object.email.should == 'first'
    end

    it 'should return nil if no email addresses' do
      Pupa::ContactDetailList.new.email.should == nil
    end
  end
end
