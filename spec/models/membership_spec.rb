require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Membership do
  let :object do
    Pupa::Membership.new({
      label: "Kitchen assistant at Joe's Diner",
      person_id: 'john-q-public',
      organization_id: 'abc-inc',
      post_id: 'abc-inc-kitchen-assistant',
      end_date: '1971-12-31',
    })
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      object.to_s.should == 'john-q-public in abc-inc'
    end
  end

  describe '#fingerprint' do
    it 'should return the fingerprint' do
      object.fingerprint.should == {
        '$or' => [
          {label: "Kitchen assistant at Joe's Diner", person_id: 'john-q-public', organization_id: 'abc-inc', end_date: '1971-12-31'},
          {person_id: 'john-q-public', organization_id: 'abc-inc', post_id: 'abc-inc-kitchen-assistant', end_date: '1971-12-31'},
        ],
      }
    end
  end
end
