require 'java'
require 'rubygems'

begin
  # will work from gem, since lib dir is in gem require_paths
  require 'red_storm/version'
rescue LoadError
  # will work within RedStorm dev project
  $:.unshift './lib'
  require 'red_storm/version'
end

java_import 'backtype.storm.Config'
java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.StormSubmitter'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'

java_import 'redstorm.storm.jruby.JRubyBolt'
java_import 'redstorm.storm.jruby.JRubySpout'

java_package 'redstorm'

# TopologyLauncher is the application entry point when launching a topology. Basically it will 
# call require on the specified Ruby topology/project class file path and call its start method
class TopologyLauncher

  java_signature 'void main(String[])'
  def self.main(args)
    unless args.size > 0 
      puts("Usage: redstorm topology_class_file_name")
      exit(1)
    end
    class_path = args[0]
    clazz = camel_case(class_path.split('/').last.split('.').first)
    puts("RedStorm v#{RedStorm::VERSION} starting topology #{clazz}")
    require class_path
    Object.module_eval(clazz).new.start(class_path)
  end

  private 

  def self.camel_case(s)
    s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end
