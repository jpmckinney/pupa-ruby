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
      @person = Pupa::Person.new
    end

    def scrape_people
      Fiber.yield(person)
    end
  end

  before :all do
    PersonProcessor.add_scraping_task(:people)
  end

  let :io do
    StringIO.new
  end

  let :processor do
    PersonProcessor.new('/tmp', level: 'WARN', logdev: io)
  end

  describe '#get' do
    it 'should send a GET request' do
      processor.get('http://httpbin.org/get', 'foo=bar')['args'].should == {'foo' => 'bar'}
    end

    it 'should automatically parse the response' do
      processor.get('http://httpbin.org/get').should be_a(Hash)
    end
  end

  describe '#post' do
    it 'should send a POST request' do
      processor.post('http://httpbin.org/post', 'foo=bar')['form'].should == {'foo' => 'bar'}
    end

    it 'should automatically parse the response' do
      processor.post('http://httpbin.org/post').should be_a(Hash)
    end
  end

  describe '#add_scraping_task' do
    it 'should add a scraping task and define a lazy method' do
      PersonProcessor.tasks.should == [:people]
      processor.should respond_to(:people)
    end
  end

  describe '#dump_scraped_objects' do
    let :path do
      path = "/tmp/person_#{processor.person._id}.json"
    end

    it 'should not overwrite an existing file' do
      FileUtils.touch(path)
      expect{processor.dump_scraped_objects(:people)}.to raise_error(Pupa::Errors::DuplicateObjectIdError)
      FileUtils.rm(path)
    end

    it 'should dump a JSON document' do
      processor.dump_scraped_objects(:people)
      File.exist?(path).should == true
      io.string.should_not match('http://popoloproject.com/schemas/person.json')
    end

    it 'should validate the object' do
      processor.make_person_invalid
      processor.dump_scraped_objects(:people)
      io.string.should match('http://popoloproject.com/schemas/person.json')
    end
  end

  describe '#import' do
    before :each do
      Pupa.session = Moped::Session.new(['localhost:27017'], database: 'pupa_test')
      Pupa.session.collections.each(&:drop)
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
          parent: {_type: 'pupa/organization', name: 'Parent'},
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

    it 'should use a dependency graph if possible' do
      processor.should_receive(:load_scraped_objects).and_return(graphable)

      Pupa::Processor::DependencyGraph.any_instance.should_receive(:tsort).and_return(['2', '1'])
      processor.import
    end

    it 'should not use a dependency graph if not possible' do
      processor.should_receive(:load_scraped_objects).and_return(ungraphable)

      Pupa::Processor::DependencyGraph.any_instance.should_not_receive(:tsort)
      processor.import
    end

    it 'should remove duplicate objects and re-assign foreign keys' do
      processor.should_receive(:load_scraped_objects).and_return(graphable)

      processor.import
      documents = Pupa.session[:organizations].find.entries
      documents.size.should == 2
      documents[0].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '2', '_type' => 'pupa/organization', 'name' => 'Parent'}
      documents[1].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '1', '_type' => 'pupa/organization', 'name' => 'Child', 'parent_id' => '2'}
    end

    it 'should resolve foreign objects' do
      processor.should_receive(:load_scraped_objects).and_return(ungraphable)

      processor.import
      documents = Pupa.session[:organizations].find.entries
      documents.size.should == 2
      documents[0].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '5', '_type' => 'pupa/organization', 'name' => 'Parent'}
      documents[1].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '4', '_type' => 'pupa/organization', 'name' => 'Child', 'parent_id' => '5'}
    end

    context 'with existing documents' do
      before :each do
        processor.should_receive(:load_scraped_objects).and_return(graphable)
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

      let :unresolvable_foreign_key do
        {
          'a' => Pupa::Organization.new({
            _id: 'a',
            name: 'Child',
            parent: {_type: 'pupa/organization', name: 'Parent'},
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
            parent: {_type: 'pupa/organization', name: 'Nonexistent'},
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
            parent: {_type: 'pupa/organization', name: 'Parent'},
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

      it 'should resolve foreign keys' do
        processor.should_receive(:load_scraped_objects).and_return(resolvable_foreign_key)

        processor.import
        documents = Pupa.session[:organizations].find.entries
        documents.size.should == 2
        documents[0].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '2', '_type' => 'pupa/organization', 'name' => 'Parent'}
        documents[1].slice('_id', '_type', 'name', 'parent_id').should == {'_id' => '1', '_type' => 'pupa/organization', 'name' => 'Child', 'parent_id' => '2'}
      end

      it 'should raise an error if a foreign key cannot be resolved' do
        processor.should_receive(:load_scraped_objects).and_return(unresolvable_foreign_key)
        expect{processor.import}.to raise_error(Pupa::Errors::UnprocessableEntity)
      end

      it 'should raise an error if a foreign object cannot be resolved' do
        processor.should_receive(:load_scraped_objects).and_return(unresolvable_foreign_object)
        expect{processor.import}.to raise_error(Pupa::Errors::UnprocessableEntity)
      end

      it 'should raise an error if a duplicate was inadvertently saved' do
        processor.should_receive(:load_scraped_objects).and_return(duplicate_documents)
        expect{processor.import}.to raise_error(Pupa::Errors::DuplicateDocumentError)
      end
    end
  end
end
