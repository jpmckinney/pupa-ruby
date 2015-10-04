require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Organization do
  let :object do
    Pupa::Organization.new(name: 'ABC, Inc.', classification: 'Corporation', parent_id: 'holding-company-corp')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      expect(object.to_s).to eq('ABC, Inc.')
    end
  end

  describe '#fingerprint' do
    it 'should return the fingerprint' do
      expect(object.fingerprint).to eq({
        '$or' => [
          {'name' => 'ABC, Inc.', classification: 'Corporation', parent_id: 'holding-company-corp'},
          {'other_names.name' => 'ABC, Inc.', classification: 'Corporation', parent_id: 'holding-company-corp'},
        ],
      })
    end
  end
end
