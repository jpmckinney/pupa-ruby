require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Processor::Persistence do
  before :all do
    Pupa.session = Moped::Session.new(['localhost:27017'], database: 'pupa_test')
    Pupa.session.collections.each(&:drop)

    Pupa::Processor::Persistence.new(Pupa::Person.new(_id: 'existing', name: 'existing', email: 'existing@example.com')).save

    Pupa.session[:people].insert(_type: 'pupa/person', name: 'non-unique')
    Pupa.session[:people].insert(_type: 'pupa/person', name: 'non-unique')
  end

  describe '.find' do
    it 'should return nil if no matches' do
      Pupa::Processor::Persistence.find(_type: 'pupa/person', name: 'nonexistent').should == nil
    end

    it 'should return a document if one match' do
      Pupa::Processor::Persistence.find(_type: 'pupa/person', name: 'existing').should be_a(Hash)
    end

    it 'should raise an error if many matches' do
      expect{Pupa::Processor::Persistence.find(_type: 'pupa/person', name: 'non-unique')}.to raise_error(Pupa::Errors::TooManyMatches)
    end
  end

  describe '#save' do
    it 'should insert a document if no matches' do
      Pupa::Processor::Persistence.new(Pupa::Person.new(_id: 'new', name: 'new', email: 'new@example.com')).save.should == [true, 'new']
      Pupa::Processor::Persistence.find(_type: 'pupa/person', name: 'new')['email'].should == 'new@example.com'
    end

    it 'should update a document if one match' do
      Pupa::Processor::Persistence.new(Pupa::Person.new(_id: 'changed', name: 'existing', email: 'changed@example.com')).save.should == [false, 'existing']
      Pupa::Processor::Persistence.find(_type: 'pupa/person', name: 'existing')['email'].should == 'changed@example.com'
    end

    it 'should raise an error if many matches' do
      expect{Pupa::Processor::Persistence.new(Pupa::Person.new(name: 'non-unique')).save}.to raise_error(Pupa::Errors::TooManyMatches)
    end
  end
end
