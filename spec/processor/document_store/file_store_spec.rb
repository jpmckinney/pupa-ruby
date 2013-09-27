require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Processor::DocumentStore::FileStore do
  let :store do
    Pupa::Processor::DocumentStore::FileStore.new(File.expand_path(File.join('..', '..', 'fixtures'), __dir__))
  end

  describe '#exist?' do
    it 'should return true if the store contains an entry for the given key' do
      store.exist?('foo.json').should == true
    end

    it 'should return false if the store does not contain an entry for the given key' do
      store.exist?('nonexistent').should == false
    end
  end

  describe '#entries' do
    it 'should return all keys in the store' do
      store.entries.sort.should == %w(bar.json baz.json foo.json)
    end
  end

  describe '#read' do
    it 'should return the value of the given key' do
      store.read('foo.json').should == {'name' => 'foo'}
    end
  end

  describe '#read_multi' do
    it 'should return the values of the given keys' do
      store.read_multi(%w(foo.json bar.json)).should == [{'name' => 'foo'}, {'name' => 'bar'}]
    end
  end

  describe '#write' do
    it 'should write an entry with the given value for the given key' do
      store.exist?('new.json').should == false
      store.write('new.json', {'name' => 'new'})
      store.read('new.json').should == {'name' => 'new'}
      store.delete('new.json') # cleanup
    end
  end

  describe '#write_multi' do
    it 'should write entries with the given values for the given keys' do
      pairs = {}
      %w(new1 new2).each do |name|
        pairs["#{name}.json"] = {'name' => name}
      end

      pairs.keys.each do |name|
        store.exist?(name).should == false
      end
      store.write_multi(pairs)
      store.read_multi(pairs.keys).should == [{'name' => 'new1'}, {'name' => 'new2'}]
      pairs.keys.each do |name| # cleanup
        store.delete(name)
      end
    end
  end

  describe '#delete' do
    it 'should delete an entry with the given key from the store' do
      store.write('new.json', {'name' => 'new'})
      store.exist?('new.json').should == true
      store.delete('new.json')
      store.exist?('new.json').should == false
    end
  end

  describe '#clear' do
    it 'should delete all entries from the store' do
      store.entries.sort.should == %w(bar.json baz.json foo.json)
      store.clear
      store.entries.should == []

      %w(bar baz foo).each do |name| # cleanup
        store.write("#{name}.json", {'name' => name})
      end
    end
  end
end
