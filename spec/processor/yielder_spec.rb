require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::Yielder do
  let :yielder do
    Pupa::Processor::Yielder.new do
      10.times do |n|
        Fiber.yield(n)
      end
    end
  end

  let :raiser do
    Pupa::Processor::Yielder.new do
      raise
    end
  end

  describe '#each' do
    it 'should iterate over the items in the enumeration' do
      array = []
      yielder.each do |n|
        array << n
      end
      array.should == (0..9).to_a
    end

    it 'should be composable with other iterators' do
      yielder.each.map{|n| n}.should == (0..9).to_a
    end
  end

  describe '#next' do
    it 'should return the next item in the enumeration' do
      array = []
      10.times do |n|
        array << yielder.next
      end
      array.should == (0..9).to_a
    end

    it 'should raise an error if the enumerator is at the end' do
      expect{11.times{yielder.next}}.to raise_error(StopIteration)
    end
  end

  describe '#to_enum' do
    it 'should return an enumerator' do
      yielder.to_enum.should be_a(Enumerator)
    end

    it 'should return a lazy enumerator' do
      expect{raiser.to_enum}.to_not raise_error
    end
  end
end
