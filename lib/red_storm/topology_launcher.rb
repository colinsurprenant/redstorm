require 'java'
# require 'rubygems'

# begin
#   # will work from gem, since lib dir is in gem require_paths
#   require 'red_storm'
# rescue LoadError
#   # will work within RedStorm dev project
#   $:.unshift './lib'
#   require 'red_storm'
# end

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

    puts("****TOPOLOGY LAUNCHER PRE ** PWD=#{Dir.pwd}")
    puts("****TOPOLOGY LAUNCHER PRE ** RedStorm::JAR_CONTEXT=#{RedStorm::JAR_CONTEXT}")
    puts("****TOPOLOGY LAUNCHER PRE ** RedStorm::LAUNCH_PATH=#{RedStorm::LAUNCH_PATH}")
    puts("****TOPOLOGY LAUNCHER PRE ** RedStorm::BASE_PATH=#{RedStorm::BASE_PATH}")
    puts("****TOPOLOGY LAUNCHER PRE ** RedStorm::LIB_PATH=#{RedStorm::LIB_PATH}")

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

    puts("****TOPOLOGY LAUNCHER POST ** PWD=#{Dir.pwd}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::JAR_CONTEXT=#{RedStorm::JAR_CONTEXT}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::LAUNCH_PATH=#{RedStorm::LAUNCH_PATH}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::REDSTORM_HOME=#{RedStorm::REDSTORM_HOME}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::TARGET_PATH=#{RedStorm::TARGET_PATH}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::GEM_PATH=#{RedStorm::GEM_PATH}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::BUNDLER_PATH=#{RedStorm::BUNDLE_PATH}")
    puts("****TOPOLOGY LAUNCHER POST ** RedStorm::BUNDLE_GEMFILE=#{RedStorm::BUNDLE_GEMFILE}")
    puts("****TOPOLOGY LAUNCHER POST ** ENV['BUNDLE_GEMFILE']=#{ENV['BUNDLE_GEMFILE']}")
    puts("****TOPOLOGY LAUNCHER POST ** ENV['BUNDLE_PATH']=#{ENV['BUNDLE_PATH']}")
    puts("****TOPOLOGY LAUNCHER POST ** ENV['GEM_PATH']=#{ENV['GEM_PATH']}")


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
