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
    require 'json'

    require 'octokit'

    Octokit.contents('popolo-project/popolo-spec', path: 'schemas', ref: 'gh-pages').each do |file|
      response = Octokit.contents('popolo-project/popolo-spec', path: file.path, ref: 'gh-pages')
      if response.encoding == 'base64'
        content = JSON.load(Base64.decode64(response.content))
      else
        raise "Can't handle #{response.encoding} encoding"
      end
      content['id'] = content['id'].sub('http://www.popoloproject.com/schemas/', '')
      File.open(File.expand_path(File.join('schemas', 'popolo', file.name), __dir__), 'w') do |f|
        f.write(JSON.dump(content))
      end
    end
  end
end
