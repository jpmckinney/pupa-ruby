require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Processor::DocumentStore::RedisStore do
  def store
    Pupa::Processor::DocumentStore::RedisStore.new('redis://localhost/15')
  end

  before :all do
    store.clear
    %w(foo bar baz).each do |name|
      store.write("#{name}.json", {name: name})
    end
  end

  describe '#exist?' do
    it 'should return true if the store contains an entry for the given key' do
      expect(store.exist?('foo.json')).to eq(true)
    end

    it 'should return false if the store does not contain an entry for the given key' do
      expect(store.exist?('nonexistent')).to eq(false)
    end
  end

  describe '#entries' do
    it 'should return all keys in the store' do
      expect(store.entries.sort).to eq(%w(bar.json baz.json foo.json))
    end
  end

  describe '#read' do
    it 'should return the value of the given key' do
      expect(store.read('foo.json')).to eq({'name' => 'foo'})
    end
  end

  describe '#read_multi' do
    it 'should return the values of the given keys' do
      expect(store.read_multi(%w(foo.json bar.json))).to eq([{'name' => 'foo'}, {'name' => 'bar'}])
    end
  end

  describe '#write' do
    it 'should write an entry with the given value for the given key' do
      expect(store.exist?('new.json')).to eq(false)
      store.write('new.json', {name: 'new'})
      expect(store.read('new.json')).to eq({'name' => 'new'})
      store.delete('new.json') # cleanup
    end
  end

  describe '#write_unless_exists' do
    it 'should write an entry with the given value for the given key' do
      expect(store.exist?('new.json')).to eq(false)
      expect(store.write_unless_exists('new.json', {name: 'new'})).to eq(true)
      expect(store.read('new.json')).to eq({'name' => 'new'})
      store.delete('new.json') # cleanup
    end

    it 'should not write an entry with the given value for the given key if the key exists' do
      expect(store.write_unless_exists('foo.json', {name: 'new'})).to eq(false)
      expect(store.read('foo.json')).to eq({'name' => 'foo'})
    end
  end

  describe '#write_multi' do
    it 'should write entries with the given values for the given keys' do
      pairs = {}
      %w(new1 new2).each do |name|
        pairs["#{name}.json"] = {name: name}
      end

      pairs.keys.each do |name|
        expect(store.exist?(name)).to eq(false)
      end
      store.write_multi(pairs)
      expect(store.read_multi(pairs.keys)).to eq([{'name' => 'new1'}, {'name' => 'new2'}])
      pairs.keys.each do |name| # cleanup
        store.delete(name)
      end
    end
  end

  describe '#delete' do
    it 'should delete an entry with the given key from the store' do
      store.write('new.json', {name: 'new'})
      expect(store.exist?('new.json')).to eq(true)
      store.delete('new.json')
      expect(store.exist?('new.json')).to eq(false)
    end
  end

  describe '#clear' do
    it 'should delete all entries from the store' do
      expect(store.entries.sort).to eq(%w(bar.json baz.json foo.json))
      store.clear
      expect(store.entries).to eq([])

      %w(bar baz foo).each do |name| # cleanup
        store.write("#{name}.json", {name: name})
      end
    end
  end
end
