require 'java'

# see https://github.com/colinsurprenant/redstorm/issues/7
module Backtype
  java_import 'backtype.storm.Config'
end

java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.StormSubmitter'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'

java_import 'redstorm.storm.jruby.JRubyBolt'
java_import 'redstorm.storm.jruby.JRubySpout'

java_package 'redstorm'

# setup some environment constants
# this is required here and in red_storm.rb which are both 
# entry points in redstorm. 
module RedStorm
  LAUNCH_PATH = File.expand_path(File.dirname(__FILE__))
  JAR_CONTEXT = !!(LAUNCH_PATH =~ /\.jar!$/)

  if JAR_CONTEXT
    BASE_PATH = LAUNCH_PATH
    LIB_PATH = "#{BASE_PATH}/lib"
  else
    BASE_PATH = Dir.pwd
    LIB_PATH = "#{BASE_PATH}/target/lib"
  end
end

# TopologyLauncher is the application entry point when launching a topology. Basically it will 
# call require on the specified Ruby topology class file path and call its start method
class TopologyLauncher

  java_signature 'void main(String[])'
  def self.main(args)
    # this is the entry point for these two contexts:
    # - runnig a topology in local mode. the current Ruby env will stay the same at topology execution
    # - submitting a topology in cluster mode. the current Ruby env will be valid only at topology submission. At topology execution
    #   in the cluster, the new entry point will be the red_storm.rb, topology_launcher will not be called

    unless args.size > 1
      puts("Usage: redstorm local|cluster topology_class_file_name")
      exit(1)
    end

    env = args[0].to_sym
    class_path = args[1]

    $:.unshift "#{RedStorm::BASE_PATH}"
    $:.unshift "#{RedStorm::LIB_PATH}"

    require 'red_storm/environment'
    RedStorm.setup_gems

    require "#{class_path}" 

    topology_name = RedStorm::Configuration.topology_class.respond_to?(:topology_name) ? "/#{RedStorm::Configuration.topology_class.topology_name}" : ''
    puts("RedStorm v#{RedStorm::VERSION} starting topology #{RedStorm::Configuration.topology_class.name}#{topology_name} in #{env.to_s} environment")
    RedStorm::Configuration.topology_class.new.start(class_path, env)
  end

  private 

  def self.camel_case(s)
    s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end
