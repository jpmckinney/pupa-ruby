require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Person do
  let :object do
    Pupa::Person.new(name: 'Mr. John Q. Public, Esq.')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == 'Mr. John Q. Public, Esq.'
    end
  end

  describe '#fingerprint' do
    it 'should return the fingerprint' do
      object.fingerprint.should == {
        '$or' => [
          {'name' => 'Mr. John Q. Public, Esq.'},
          {'other_names.name' => 'Mr. John Q. Public, Esq.'},
        ],
      }
    end
  end
end
