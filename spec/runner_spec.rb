require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pupa::Runner do
  class TestProcessor < Pupa::Processor
    def scrape_people
    end

    def scrape_organizations
    end
  end

  before :all do
    TestProcessor.add_scraping_task(:people)
    TestProcessor.add_scraping_task(:organizations)
  end

  let :dry_runner do
    runner = Pupa::Runner.new(TestProcessor, level: 'UNKNOWN', dry_run: true)
    runner.add_action(name: 'example', description: 'An example action')
    runner
  end

  let :runner do
    Pupa::Runner.new(TestProcessor, level: 'UNKNOWN')
  end

  describe '#initialize' do
    it 'should accept default options' do
      dry_runner.options.level.should_not == 'INFO'
    end
  end

  describe '#add_action' do
    it 'should add an action' do
      dry_runner.actions.last.to_h.should == {name: 'example', description: 'An example action'}
    end
  end

  describe '#run' do
    def dry_run(argv = [], **kwargs)
      begin
        dry_runner.run(argv, kwargs)
      rescue SystemExit
        # pass
      end
    end

    it 'should accept overridden options' do
      dry_run(['--quiet'], level: 'ERROR')
      dry_runner.options.level.should == 'ERROR'
    end

    it 'should use default actions if none set' do
      dry_run
      dry_runner.options.actions.should == %w(scrape import)
    end

    it 'should use default tasks if none set' do
      dry_run
      dry_runner.options.tasks.should == %i(people organizations)
    end

    # Unlike an action, it's not possible for a task to be undefined, because
    # `add_scraping_task` would raise an error first.
    it 'should abort if the action is not defined' do
      expect{dry_runner.run(['--action', 'example'])}.to raise_error(SystemExit, "`example` is not a rspec action. See `rspec --help` for a list of available actions.")
    end

    it 'should not run any actions on a dry run' do
      expect{dry_runner.run([])}.to raise_error(SystemExit, nil)
    end

    it 'should run actions' do
      TestProcessor.any_instance.should_receive(:dump_scraped_objects).twice
      TestProcessor.any_instance.should_receive(:import)
      runner.run([])
    end

    it 'should run tasks' do
      TestProcessor.any_instance.should_receive(:people).and_return([])
      TestProcessor.any_instance.should_receive(:organizations).and_return([])
      runner.run([])
    end
  end
end
