require 'fileutils'
require 'optparse'
require 'ostruct'

require 'moped'

module Pupa
  class Runner
    # @param [Pupa::Processor] a processor class
    def initialize(processor_class)
      @processor_class = processor_class
      @actions         = []
      @tasks           = []
      @output_dir      = File.expand_path('scraped_data', Dir.pwd)
      @cache_dir       = File.expand_path('web_cache', Dir.pwd)
      @expires_in      = 86400 # 1 day
      @host_with_port  = 'localhost:27017'
      @database        = 'pupa'
      @level           = 'INFO'

      @available = {
        'extract' => 'Scrapes data from online sources',
        'load'    => 'Loads scraped data into a database',
      }.map do |name,description|
        OpenStruct.new(name: name, description: description)
      end
    end

    # @param [Hash] attributes the action's attributes
    # @option attributes [String] :name the action's label
    # @option attributes [String] :description a description of the action
    def add_action(attributes)
      @available << OpenStruct.new(attributes)
    end

    # Returns the command-line option parser.
    #
    # @return [OptionParser] the command-line option parser
    def opts
      @opts ||= OptionParser.new do |opts|
        opts.program_name = File.basename($PROGRAM_NAME)
        opts.banner = "Usage: #{opts.program_name}"

        opts.separator ''
        opts.separator 'Actions:'

        names = @available.map(&:name)
        padding = names.map(&:size).max
        @available.each do |action|
          opts.separator "  #{action.name.ljust(padding)}  #{action.description}\n"
        end

        opts.separator ''
        opts.separator 'Tasks:'

        @processor_class.tasks.each do |task_name|
          opts.separator "  #{task_name}"
        end

        opts.separator ''
        opts.separator 'Specific options:'
        opts.on('-a', '--action ACTION', names, 'Select an action to run (you may give this switch multiple times)', "  (#{names.join(', ')})") do |v|
          @actions << v
        end
        opts.on('-t', '--task TASK', @processor_class.tasks, 'Select an extraction task to run (you may give this switch multiple times)', "  (#{@processor_class.tasks.join(', ')})") do |v|
          @tasks << v
        end
        opts.on('-o', '--output_dir PATH', 'The directory in which to dump JSON documents') do |v|
          @output_dir = v
        end
        opts.on('-c', '--cache_dir PATH', 'The directory in which to cache HTTP requests') do |v|
          @cache_dir = v
        end
        opts.on('-e', '--expires_in SECONDS', "The cache's expiration time in seconds") do |v|
          @expires_in = v
        end
        opts.on('-H', '--host HOST:PORT', 'The host and port to MongoDB') do |v|
          @host_with_port = v
        end
        opts.on('-d', '--database NAME', 'The name of the MongoDB database') do |v|
          @database = v
        end
        opts.on('-q', '--quiet', 'Show only warning and error messages') do
          @level = 'WARN'
        end
        opts.on('-s', '--silent', 'Show no messages') do
          @level = 'UNKNOWN'
        end

        opts.separator ''
        opts.separator 'Common options:'
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
        opts.on_tail('-v', '--version', 'Show version') do
          puts Pupa::VERSION
          exit
        end
      end
    end

    # Runs the action. Most often run from a command-line script as:
    #
    #     runner.run(ARGV)
    #
    # @param [Array] args command-line arguments
    def run(args)
      rest = opts.parse!(args)

      if @actions.empty?
        @actions = %w(extract load)
      end
      if @tasks.empty?
        @tasks = @processor_class.tasks
      end

      processor = @processor_class.new(@output_dir, cache_dir: @cache_dir, expires_in: @expires_in, level: @level, options: Hash[*rest])

      @actions.each do |action|
        unless action == 'extract' || processor.respond_to?(action)
          abort %(`#{action}` is not a #{opts.program_name} action. See `#{opts.program_name} --help` for a list of available actions.)
        end
      end
      @tasks.each do |task_name|
        unless processor.respond_to?(task_name)
          abort %(`#{task_name}` is not a #{opts.program_name} task. See `#{opts.program_name} --help` for a list of available tasks.)
        end
      end

      puts "processor: #{@processor_class}"
      puts "actions: #{@actions.join(', ')}"
      puts "tasks: #{@tasks.join(', ')}"

      Pupa.session = Moped::Session.new([@host_with_port], database: @database)

      if @actions.delete('extract')
        FileUtils.mkdir_p(@output_dir)
        FileUtils.mkdir_p(@cache_dir)

        Dir[File.join(@output_dir, '*.json')].each do |path|
          FileUtils.rm(path)
        end

        @tasks.each do |task_name|
          processor.dump_extracted_objects(task_name)
        end
      end

      @actions.each do |action|
        processor.send(action)
      end
    end
  end
end
