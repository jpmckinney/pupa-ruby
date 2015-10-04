require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Contactable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Contactable
    end
  end

  let :object do
    klass.new
  end

  describe '#initialize' do
    it 'should initialize an empty ContactDetailList' do
      expect(object.contact_details).to be_a(Pupa::ContactDetailList)
      expect(object.contact_details).to eq([])
    end

    it 'should initialize the given ContactDetailList' do
      object = klass.new(contact_details: [{type: 'email', value: 'ceo@example.com', note: 'work'}])
      expect(object.contact_details).to eq([{type: 'email', value: 'ceo@example.com', note: 'work'}])
    end
  end

  describe '#contact_details=' do
    it 'should use coerce to a ContactDetailList' do
      object.contact_details = [{type: 'email', value: 'ceo@example.com', note: 'work'}]
      expect(object.contact_details).to be_a(Pupa::ContactDetailList)
    end

    it 'should symbolize keys' do
      object.contact_details = [{'type' => 'email', 'value' => 'ceo@example.com'}]
      expect(object.contact_details).to eq([{type: 'email', value: 'ceo@example.com'}])
    end
  end

  describe '#add_contact_detail' do
    it 'should add a contact detail' do
      object.add_contact_detail('email', 'ceo@example.com', label: 'Email', note: 'work', valid_from: '2010-01-01', valid_until: '2010-12-31')
      expect(object.contact_details).to eq([{type: 'email', value: 'ceo@example.com', label: 'Email', note: 'work', valid_from: '2010-01-01', valid_until: '2010-12-31'}])
    end

    it 'should not add a contact detail without a type' do
      object.add_contact_detail(nil, 'ceo@example.com')
      object.add_contact_detail('', 'ceo@example.com')
      expect(object.contact_details.blank?).to eq(true)
    end

    it 'should not add a contact detail without a value' do
      object.add_contact_detail('email', nil)
      object.add_contact_detail('email', '')
      expect(object.contact_details.blank?).to eq(true)
    end
  end
end
