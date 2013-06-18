require 'rspec/core/rake_task'

desc "run specs"
RSpec::Core::RakeTask.new(:spec) do
  system("ruby -v")
  module RedStorm; SPECS_CONTEXT = true; end
end

task :default => :spec

load 'lib/tasks/red_storm.rake'
