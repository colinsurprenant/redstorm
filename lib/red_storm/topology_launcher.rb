require 'java'

# This hack get rif of the "Use RbConfig instead of obsolete and deprecated Config"
# deprecation warning that is triggered by "java_import 'backtype.storm.Config'".
Object.send :remove_const, :Config
Config = RbConfig

# see https://github.com/colinsurprenant/redstorm/issues/7
module Backtype
  java_import 'backtype.storm.Config'
end

java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.LocalDRPC'
java_import 'backtype.storm.StormSubmitter'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.coordination.BatchBoltExecutor'
java_import 'backtype.storm.drpc.LinearDRPCTopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'

# java_import 'redstorm.storm.jruby.JRubyBolt'
# java_import 'redstorm.storm.jruby.JRubySpout'
# java_import 'redstorm.storm.jruby.JRubyBatchBolt'
# java_import 'redstorm.storm.jruby.JRubyBatchCommitterBolt'
# java_import 'redstorm.storm.jruby.JRubyBatchSpout'
# java_import 'redstorm.storm.jruby.JRubyTransactionalSpout'
# java_import 'redstorm.storm.jruby.JRubyTransactionalBolt'
# java_import 'redstorm.storm.jruby.JRubyTransactionalCommitterBolt'

java_package 'redstorm'

# TopologyLauncher is the application entry point when launching a topology. Basically it will
# call require on the specified Ruby topology class file path and call its start method
class TopologyLauncher

  java_signature 'void main(String[])'
  def self.main(args)
    unless args.size > 1
      puts("Usage: redstorm local|cluster topology_class_file_name")
      exit(1)
    end

    env = args[0].to_sym
    class_path = args[1]

    launch_path = Dir.pwd
    $:.unshift File.expand_path(launch_path)
    $:.unshift File.expand_path(launch_path + '/lib')
    $:.unshift File.expand_path(launch_path + '/target/lib')

    require "#{class_path}"

    if RedStorm::Configuration.topology_class.nil? || !RedStorm::Configuration.topology_class.method_defined?(:start)
      puts("\nERROR: invalid topology class. make sure your topology class is a subclass of one of the DSL topology classes or that your class sets RedStorm::Configuration.topology_class and defines the start method\n\n")
      exit(1)
    end

    topology_name = RedStorm::Configuration.topology_class.respond_to?(:topology_name) ? "/#{RedStorm::Configuration.topology_class.topology_name}" : ''
    puts("RedStorm v#{RedStorm::VERSION} starting topology #{RedStorm::Configuration.topology_class.name}#{topology_name} in #{env.to_s} environment")
    RedStorm::Configuration.topology_class.new.start(env)
  end

  private

  def self.camel_case(s)
    s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end
