require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yard, you must: gem install yard'
  end
end

namespace :popolo do
  desc 'Update Popolo schemas'
  task :schemas do
    require 'base64'

    require 'octokit'

    Octokit.contents('opennorth/popolo-spec', path: 'schemas', ref: 'gh-pages').each do |file|
      response = Octokit.contents('opennorth/popolo-spec', path: file.path, ref: 'gh-pages')
      if response.encoding == 'base64'
        content = Base64.decode64(response.content)
      else
        raise "Can't handle #{response.encoding} encoding"
      end
      File.open(File.expand_path(File.join('schemas', 'popolo', file.name), __dir__), 'w') do |f|
        f.write(content)
      end
    end
  end
end
