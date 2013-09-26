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
      {
        type: 'custom',
        value: 'content',
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

  describe '#find_by_type' do
    it 'should return the value of the first contact detail matching the type' do
      object.find_by_type('custom').should == 'content'
    end

    it 'should return nil if no contact detail matches the type' do
      Pupa::ContactDetailList.new.find_by_type('custom').should == nil
    end
  end
end
