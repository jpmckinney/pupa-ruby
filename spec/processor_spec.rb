require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pupa::Processor do
  class PersonProcessor < Pupa::Processor
    def person
      @person ||= make_person_valid
    end

    def make_person_valid
      @person = Pupa::Person.new(name: 'foo')
    end

    def make_person_invalid
      @person = Pupa::Person.new(name: ['foo'])
    end

    def scrape_people
      dispatch(person)
    end
  end

  before :all do
    PersonProcessor.add_scraping_task(:people)
  end

  let :io do
    StringIO.new
  end

  let :processor do
    PersonProcessor.new('/tmp', database_url: 'mongodb://localhost:27017/pupa_test', level: 'WARN', logdev: io)
  end

  let :novalidate do
    PersonProcessor.new('/tmp', database_url: 'mongodb://localhost:27017/pupa_test', level: 'WARN', logdev: io, validate: false)
  end

  describe '#get' do
    it 'should send a GET request' do
      expect(processor.get('http://httpbin.org/get', 'foo=bar')['args']).to eq({'foo' => 'bar'})
    end

    it 'should automatically parse the response' do
      expect(processor.get('http://httpbin.org/get')).to be_a(Hash)
    end
  end

  describe '#post' do
    it 'should send a POST request' do
      expect(processor.post('http://httpbin.org/post', 'foo=bar')['form']).to eq({'foo' => 'bar'})
    end

    it 'should automatically parse the response' do
      expect(processor.post('http://httpbin.org/post')).to be_a(Hash)
    end
  end

  describe '.add_scraping_task' do
    it 'should add a scraping task and define a lazy method' do
      expect(PersonProcessor.tasks).to eq([:people])
      expect(processor).to respond_to(:people)
    end
  end

  describe '#dump_scraped_objects' do
    let :path do
      path = "/tmp/person_#{processor.person._id}.json"
    end

    it 'should return the number of scraped objects by type' do
      expect(processor.dump_scraped_objects(:people)).to eq({'pupa/person' => 1})
    end

    it 'should not overwrite an existing file' do
      File.open(path, 'w') {}
      expect{processor.dump_scraped_objects(:people)}.to raise_error(Pupa::Errors::DuplicateObjectIdError)
      File.delete(path)
    end

    it 'should dump a JSON document' do
      processor.dump_scraped_objects(:people)
      expect(File.exist?(path)).to eq(true)
      expect(io.string).not_to match("The property '#/")
    end

    it 'should validate the object' do
      processor.make_person_invalid
      processor.dump_scraped_objects(:people)
      expect(io.string).to match("The property '#/name' of type array did not match one or more of the following types: string, null")
    end

    it 'should not validate the object' do
      novalidate.make_person_invalid
      novalidate.dump_scraped_objects(:people)
      expect(io.string).not_to match("The property '#/name' of type array did not match one or more of the following types: string, null")
    end
  end

  describe '#import' do
    before :each do
      processor.connection.raw_connection[:organizations].drop
    end

    let :_type do
      'pupa/organization'
    end

    let :graphable do
      {
        '1' => Pupa::Organization.new({
          _id: '1',
          name: 'Child',
          parent_id: '3',
        }),
        '2' => Pupa::Organization.new({
          _id: '2',
          name: 'Parent',
        }),
        '3' => Pupa::Organization.new({
          _id: '3',
          name: 'Parent',
        }),
      }
    end

    let :ungraphable do
      {
        '4' => Pupa::Organization.new({
          _id: '4',
          name: 'Child',
          parent: {_type: _type, name: 'Parent'},
        }),
        '5' => Pupa::Organization.new({
          _id: '5',
          name: 'Parent',
        }),
        '6' => Pupa::Organization.new({
          _id: '6',
          name: 'Parent',
        }),
      }
    end

    let :foreign_keys_on_foreign_objects do
      {
        '7' => Pupa::Organization.new({
          _id: '7',
          name: 'Child',
          parent: {_type: _type, name: 'Parent'},
        }),
        '8' => Pupa::Organization.new({
          _id: '8',
          name: 'Grandchild',
          parent: {_type: _type, foreign_keys: {parent_id: '9'}}
        }),
        '9' => Pupa::Organization.new({
          _id: '9',
          name: 'Parent',
        }),
      }
    end

    it 'should use a dependency graph if possible' do
      expect(processor).to receive(:load_scraped_objects).and_return(graphable)

      expect_any_instance_of(Pupa::Processor::DependencyGraph).to receive(:tsort).and_return(['2', '1'])
      processor.import
    end

    it 'should remove duplicate objects and re-assign foreign keys' do
      expect(processor).to receive(:load_scraped_objects).and_return(graphable)

      processor.import
      documents = processor.connection.raw_connection[:organizations].find.entries
      expect(documents.size).to eq(2)
      expect(documents[0].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '2', '_type' => _type, 'name' => 'Parent'})
      expect(documents[1].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '1', '_type' => _type, 'name' => 'Child', 'parent_id' => '2'})
    end

    it 'should not use a dependency graph if not possible' do
      expect(processor).to receive(:load_scraped_objects).and_return(ungraphable)

      expect_any_instance_of(Pupa::Processor::DependencyGraph).not_to receive(:tsort)
      processor.import
    end

    it 'should remove duplicate objects and resolve foreign objects' do
      expect(processor).to receive(:load_scraped_objects).and_return(ungraphable)

      processor.import
      documents = processor.connection.raw_connection[:organizations].find.entries
      expect(documents.size).to eq(2)
      expect(documents[0].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '5', '_type' => _type, 'name' => 'Parent'})
      expect(documents[1].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '4', '_type' => _type, 'name' => 'Child', 'parent_id' => '5'})
    end

    it 'should resolve foreign keys on foreign objects' do
      expect(processor).to receive(:load_scraped_objects).and_return(foreign_keys_on_foreign_objects)

      processor.import
      documents = processor.connection.raw_connection[:organizations].find.entries
      expect(documents.size).to eq(3)
      expect(documents[0].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '9', '_type' => _type, 'name' => 'Parent'})
      expect(documents[1].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '7', '_type' => _type, 'name' => 'Child', 'parent_id' => '9'})
      expect(documents[2].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '8', '_type' => _type, 'name' => 'Grandchild', 'parent_id' => '7'})
    end

    context 'with existing documents' do
      before :each do
        expect(processor).to receive(:load_scraped_objects).and_return(graphable)
        processor.import
      end

      let :resolvable_foreign_key do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent_id: 'c',
          }),
          'b' => Pupa::Organization.new({
            _id: 'b',
            name: 'Parent',
          }),
          'c' => Pupa::Organization.new({
            _id: 'c',
            name: 'Parent',
          }),
        }
      end

      # Use a foreign object to not use a dependency graph.
      let :unresolvable_foreign_key do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent: {_type: _type, name: 'Parent'},
          }),
          'b' => Pupa::Organization.new({
            _id: 'b',
            name: 'Parent',
          }),
          'c' => Pupa::Organization.new({
            _id: 'c',
            name: 'Child',
            parent_id: 'nonexistent',
          }),
        }
      end

      let :unresolvable_foreign_object do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent: {_type: _type, name: 'Nonexistent'},
          }),
          'b' => Pupa::Organization.new({
            _id: 'b',
            name: 'Parent',
          }),
          'c' => Pupa::Organization.new({
            _id: 'c',
            name: 'Child',
            parent_id: 'b',
          }),
        }
      end

      let :duplicate_documents do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent: {_type: _type, name: 'Parent'},
          }),
          'b' => Pupa::Organization.new({
            _id: 'b',
            name: 'Parent',
          }),
          'c' => Pupa::Organization.new({
            _id: 'c',
            name: 'Child',
            parent_id: 'b',
          }),
        }
      end

      let :resolvable_foreign_keys_on_foreign_objects do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent: {_type: _type, name: 'Parent'},
          }),
          'b' => Pupa::Organization.new({
            _id: 'b',
            name: 'Grandchild',
            parent: {_type: _type, foreign_keys: {parent_id: 'c'}}
          }),
          'c' => Pupa::Organization.new({
            _id: 'c',
            name: 'Parent',
          }),
        }
      end

      it 'should resolve foreign keys' do
        expect(processor).to receive(:load_scraped_objects).and_return(resolvable_foreign_key)

        processor.import
        documents = processor.connection.raw_connection[:organizations].find.entries
        expect(documents.size).to eq(2)
        expect(documents[0].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '2', '_type' => _type, 'name' => 'Parent'})
        expect(documents[1].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '1', '_type' => _type, 'name' => 'Child', 'parent_id' => '2'})
      end

      it 'should raise an error if a foreign key cannot be resolved' do
        expect(processor).to receive(:load_scraped_objects).and_return(unresolvable_foreign_key)
        expect{processor.import}.to raise_error(Pupa::Errors::UnprocessableEntity)
      end

      it 'should raise an error if a foreign object cannot be resolved' do
        expect(processor).to receive(:load_scraped_objects).and_return(unresolvable_foreign_object)
        expect{processor.import}.to raise_error(Pupa::Errors::UnprocessableEntity)
      end

      it 'should raise an error if a duplicate was inadvertently saved' do
        expect(processor).to receive(:load_scraped_objects).and_return(duplicate_documents)
        expect{processor.import}.to raise_error(Pupa::Errors::DuplicateDocumentError)
      end

      it 'should resolve foreign keys on foreign objects' do
        expect(processor).to receive(:load_scraped_objects).and_return(resolvable_foreign_keys_on_foreign_objects)

        processor.import
        documents = processor.connection.raw_connection[:organizations].find.entries
        expect(documents.size).to eq(3)
        expect(documents[0].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '2', '_type' => _type, 'name' => 'Parent'})
        expect(documents[1].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => '1', '_type' => _type, 'name' => 'Child', 'parent_id' => '2'})
        expect(documents[2].slice('_id', '_type', 'name', 'parent_id')).to eq({'_id' => 'b', '_type' => _type, 'name' => 'Grandchild', 'parent_id' => '1'})
      end
    end
  end
end
