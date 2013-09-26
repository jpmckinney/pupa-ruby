require 'fileutils'
require 'optparse'
require 'ostruct'

require 'moped'

module Pupa
  class Runner
    attr_reader :options, :actions

    # @param [Pupa::Processor] a processor class
    # @param [Hash] defaults change any default options
    def initialize(processor_class, defaults = {})
      @processor_class = processor_class

      @options = OpenStruct.new({
        actions:        [],
        tasks:          [],
        output_dir:     File.expand_path('scraped_data', Dir.pwd),
        cache_dir:      File.expand_path('web_cache', Dir.pwd),
        expires_in:     86400, # 1 day
        host_with_port: 'localhost:27017',
        database:       'pupa',
        dry_run:        false,
        level:          'INFO',
      }.merge(defaults))

      @actions = {
        'scrape' => 'Scrapes data from online sources',
        'import' => 'Imports scraped data into a database',
      }.map do |name,description|
        OpenStruct.new(name: name, description: description)
      end
    end

    # @param [Hash] attributes the action's attributes
    # @option attributes [String] :name the action's label
    # @option attributes [String] :description a description of the action
    def add_action(attributes)
      @actions << OpenStruct.new(attributes)
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

        names = @actions.map(&:name)
        padding = names.map(&:size).max
        @actions.each do |action|
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
          options.actions << v
        end
        opts.on('-t', '--task TASK', @processor_class.tasks, 'Select a scraping task to run (you may give this switch multiple times)', "  (#{@processor_class.tasks.join(', ')})") do |v|
          options.tasks << v
        end
        opts.on('-o', '--output_dir PATH', 'The directory in which to dump JSON documents') do |v|
          options.output_dir = v
        end
        opts.on('-c', '--cache_dir PATH', 'The directory or Memcached address (e.g. memcached://localhost:11211) in which to cache HTTP requests') do |v|
          options.cache_dir = v
        end
        opts.on('-e', '--expires_in SECONDS', "The cache's expiration time in seconds") do |v|
          options.expires_in = v
        end
        opts.on('-H', '--host HOST:PORT', 'The host and port to MongoDB') do |v|
          options.host_with_port = v
        end
        opts.on('-d', '--database NAME', 'The name of the MongoDB database') do |v|
          options.database = v
        end
        opts.on('-n', '--dry-run', 'Show the plan without running any actions') do
          options.dry_run = true
        end
        opts.on('-v', '--verbose', 'Show all messages') do
          options.level = 'DEBUG'
        end
        opts.on('-q', '--quiet', 'Show only warning and error messages') do
          options.level = 'WARN'
        end
        opts.on('-s', '--silent', 'Show no messages') do
          options.level = 'UNKNOWN'
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

    # Runs the action.
    #
    # @example Run from a command-line script
    #
    #     runner.run(ARGV)
    #
    # @example Override the command-line options
    #
    #     runner.run(ARGV, expires_in: 3600) # 1 hour
    #
    # @param [Array] args command-line arguments
    # @param [Hash] overrides any overridden options
    def run(args, overrides = {})
      rest = opts.parse!(args)

      @options = OpenStruct.new(options.to_h.merge(overrides))

      if options.actions.empty?
        options.actions = %w(scrape import)
      end
      if options.tasks.empty?
        options.tasks = @processor_class.tasks
      end

      processor = @processor_class.new(options.output_dir, cache_dir: options.cache_dir, expires_in: options.expires_in, level: options.level, options: Hash[*rest])

      options.actions.each do |action|
        unless action == 'scrape' || processor.respond_to?(action)
          abort %(`#{action}` is not a #{opts.program_name} action. See `#{opts.program_name} --help` for a list of available actions.)
        end
      end

      if %w(DEBUG INFO).include?(options.level)
        puts "processor: #{@processor_class}"
        puts "actions: #{options.actions.join(', ')}"
        puts "tasks: #{options.tasks.join(', ')}"
      end

      if options.level == 'DEBUG'
        %w(output_dir cache_dir expires_in host_with_port database level).each do |option|
          puts "#{option}: #{options[option]}"
        end
        unless rest.empty?
          puts "options: #{rest.join(' ')}"
        end
      end

      exit if options.dry_run

      report = {
        plan: {
          processor: @processor_class,
          arguments: options.to_h,
          options: rest,
        },
        start: Time.now.utc,
      }

      Pupa.session = Moped::Session.new([options.host_with_port], database: options.database)

      if options.actions.delete('scrape')
        FileUtils.mkdir_p(options.output_dir)
        FileUtils.mkdir_p(options.cache_dir)

        Dir[File.join(options.output_dir, '*.json')].each do |path|
          FileUtils.rm(path)
        end

        report[:scrape] = {}
        options.tasks.each do |task_name|
          report[:scrape][task_name] = processor.dump_scraped_objects(task_name)
        end
      end

      options.actions.each do |action|
        processor.send(action)
        if processor.report.key?(action.to_sym)
          report.update(action.to_sym => processor.report[action.to_sym])
        end
      end

      report[:end] = Time.now.utc
      report[:time] = report[:end] - report[:start]
      puts JSON.dump(report)
    end
  end
end
