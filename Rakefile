require 'rubygems'
require 'bundler/setup'

load 'lib/tasks/red_storm.rake'

task :default => :spec

begin
  require 'rspec/core/rake_task'
  desc "run specs"
  task :spec do
    system("ruby -v")
    RSpec::Core::RakeTask.new
  end
rescue NameError, LoadError => e
  puts e
end
