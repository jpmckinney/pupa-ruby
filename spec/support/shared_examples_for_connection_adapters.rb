shared_examples 'SQL adapter' do |database_url|
  before :all do
    connection = Pupa::Processor::Connection::PostgreSQLAdapter.new(database_url)

    connection.raw_connection.drop_table?(:people)
    connection.raw_connection.create_table(:people) do
      primary_key :id
      String :_id
      String :_type
      String :name
      String :email
      Time :created_at
      Time :updated_at
    end

    connection.save(Pupa::Person.new(_id: 'existing', name: 'existing', email: 'existing@example.com'))
    connection.raw_connection[:people].insert(_type: 'pupa/person', name: 'non-unique')
    connection.raw_connection[:people].insert(_type: 'pupa/person', name: 'non-unique')
  end

  let :connection do
    Pupa::Processor::Connection::PostgreSQLAdapter.new(database_url)
  end

  let :_type do
    'pupa/person'
  end

  describe '.find' do
    it 'should raise an error if selector is empty' do
      expect{connection.find(_type: _type)}.to raise_error(Pupa::Errors::EmptySelectorError)
    end

    it 'should return nil if no matches' do
      connection.find(_type: _type, name: 'nonexistent').should == nil
    end

    it 'should return a document if one match' do
      connection.find(_type: _type, name: 'existing').should be_a(Hash)
    end

    it 'should raise an error if many matches' do
      expect{connection.find(_type: 'pupa/person', name: 'non-unique')}.to raise_error(Pupa::Errors::TooManyMatches)
    end
  end

  describe '.save' do
    it 'should raise an error if selector is empty' do
      expect{connection.save(Pupa::Person.new)}.to raise_error(Pupa::Errors::EmptySelectorError)
    end

    it 'should insert a document if no matches' do
      connection.save(Pupa::Person.new(_id: 'new', name: 'new', email: 'new@example.com')).should == [true, 'new']
      connection.find(_type: _type, name: 'new')['email'].should == 'new@example.com'
    end

    it 'should update a document if one match' do
      connection.save(Pupa::Person.new(_id: 'changed', name: 'existing', email: 'changed@example.com')).should == [false, 'existing']
      connection.find(_type: _type, name: 'existing')['email'].should == 'changed@example.com'
    end

    it 'should raise an error if many matches' do
      expect{connection.save(Pupa::Person.new(name: 'non-unique'))}.to raise_error(Pupa::Errors::TooManyMatches)
    end
  end
end