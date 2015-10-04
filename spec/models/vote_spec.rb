require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Vote do
  let :object do
    Pupa::Vote.new(option: 'yes', voter_id: 'john-q-public', vote_event_id: 'vote-42')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      expect(object.to_s).to eq('yes by john-q-public in vote-42')
    end
  end
end
