require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::VoteEvent do
  let :object do
    Pupa::VoteEvent.new(identifier: '1', organization_id: 'legislative-council-of-hong-kong')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      expect(object.to_s).to eq('1 in legislative-council-of-hong-kong')
    end
  end

  describe '#group_results' do
    it 'should symbolize keys' do
      object.group_results = [{'result' => 'pass', 'group' => {'name' => 'Functional constituencies'}}]
      expect(object.group_results).to eq([{result: 'pass', group: {name: 'Functional constituencies'}}])
    end
  end

  describe '#add_group_result' do
    it 'should add a group result' do
      object.add_group_result('pass', group: {name: 'Functional constituencies'})
      expect(object.group_results).to eq([{result: 'pass', group: {name: 'Functional constituencies'}}])
    end

    it 'should not add a group result without a result' do
      object.add_group_result(nil)
      object.add_group_result('')
      expect(object.group_results.blank?).to eq(true)
    end
  end

  describe '#counts' do
    it 'should symbolize keys' do
      object.counts = [{'option' => 'yes', 'value' => 9, 'group' => {'name' => 'Functional constituencies'}}]
      expect(object.counts).to eq([{option: 'yes', value: 9, group: {name: 'Functional constituencies'}}])
    end
  end

  describe '#add_count' do
    it 'should add a count' do
      object.add_count('yes', 9, group: {name: 'Functional constituencies'})
      expect(object.counts).to eq([{option: 'yes', value: 9, group: {name: 'Functional constituencies'}}])
    end

    it 'should not add a contact detail without an option' do
      object.add_count(nil, 9)
      object.add_count('', 9)
      expect(object.counts.blank?).to eq(true)
    end

    it 'should not add a contact detail without a value' do
      object.add_count('yes', nil)
      object.add_count('yes', '')
      expect(object.counts.blank?).to eq(true)
    end
  end
end
