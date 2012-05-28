require 'rubygems'
require 'rspec/core/rake_task'

load 'lib/tasks/red_storm.rake'

RSpec::Core::RakeTask.new(:spec) do
  system("ruby -v")
end

task :default => :spec
