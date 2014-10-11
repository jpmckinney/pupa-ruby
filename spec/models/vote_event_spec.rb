require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::VoteEvent do
  let :object do
    Pupa::VoteEvent.new(identifier: '1', organization_id: 'legislative-council-of-hong-kong')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == '1 in legislative-council-of-hong-kong'
    end
  end

  describe '#group_results' do
    it 'should symbolize keys' do
      object.group_results = [{'result' => 'pass', 'group' => {'name' => 'Functional constituencies'}}]
      object.group_results.should == [{result: 'pass', group: {name: 'Functional constituencies'}}]
    end
  end

  describe '#add_group_result' do
    it 'should add a group result' do
      object.add_group_result('pass', group: {name: 'Functional constituencies'})
      object.group_results.should == [{result: 'pass', group: {name: 'Functional constituencies'}}]
    end

    it 'should not add a group result without a result' do
      object.add_group_result(nil)
      object.add_group_result('')
      object.group_results.blank?.should == true
    end
  end

  describe '#counts' do
    it 'should symbolize keys' do
      object.counts = [{'option' => 'yes', 'value' => 9, 'group' => {'name' => 'Functional constituencies'}}]
      object.counts.should == [{option: 'yes', value: 9, group: {name: 'Functional constituencies'}}]
    end
  end

  describe '#add_count' do
    it 'should add a count' do
      object.add_count('yes', 9, group: {name: 'Functional constituencies'})
      object.counts.should == [{option: 'yes', value: 9, group: {name: 'Functional constituencies'}}]
    end

    it 'should not add a contact detail without an option' do
      object.add_count(nil, 9)
      object.add_count('', 9)
      object.counts.blank?.should == true
    end

    it 'should not add a contact detail without a value' do
      object.add_count('yes', nil)
      object.add_count('yes', '')
      object.counts.blank?.should == true
    end
  end
end
