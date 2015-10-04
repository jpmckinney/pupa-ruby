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
      expect(object.address).to eq('first')
    end

    it 'should return nil if no postal addresses' do
      expect(Pupa::ContactDetailList.new.address).to eq(nil)
    end
  end

  describe '#email' do
    it 'should return the first email address' do
      expect(object.email).to eq('first')
    end

    it 'should return nil if no email addresses' do
      expect(Pupa::ContactDetailList.new.email).to eq(nil)
    end
  end

  describe '#find_by_type' do
    it 'should return the value of the first contact detail matching the type' do
      expect(object.find_by_type('custom')).to eq('content')
    end

    it 'should return nil if no contact detail matches the type' do
      expect(Pupa::ContactDetailList.new.find_by_type('custom')).to eq(nil)
    end
  end
end
