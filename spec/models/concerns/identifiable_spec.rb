require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Identifiable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Identifiable
    end
  end

  let :object do
    klass.new
  end

  describe '#initialize' do
    it 'should initialize an empty IdentifierList' do
      object.identifiers.should be_a(Pupa::IdentifierList)
      object.identifiers.should == []
    end

    it 'should initialize the given IdentifierList' do
      object = klass.new(identifiers: [{identifier: '123456789', scheme: 'DUNS'}])
      object.identifiers.should == [{identifier: '123456789', scheme: 'DUNS'}]
    end
  end

  describe '#identifiers=' do
    it 'should use coerce to a IdentifierList' do
      object.identifiers = [{identifier: '123456789', scheme: 'DUNS'}]
      object.identifiers.should be_a(Pupa::IdentifierList)
    end
  end

  describe '#add_identifier' do
    it 'should add an identifier' do
      object.add_identifier('123456789', scheme: 'duns')
      object.identifiers.should == [{identifier: '123456789', scheme: 'duns'}]
    end

    it 'should not add an identifier without an identifier' do
      object.add_identifier(nil)
      object.add_identifier('')
      object.identifiers.blank?.should == true
    end
  end
end
