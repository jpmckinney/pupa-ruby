require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Area do
  let :object do
    Pupa::Area.new(name: 'Boston Ward 1')
  end

  describe '#to_s' do
    it 'should return a human-readable string' do
      expect(object.to_s).to eq('Boston Ward 1')
    end
  end
end
