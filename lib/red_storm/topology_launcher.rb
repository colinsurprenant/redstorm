require 'java'
require 'rubygems'

java_import 'backtype.storm.Config'
java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'

java_import 'backtype.storm.jruby.JRubyBolt'
java_import 'backtype.storm.jruby.JRubySpout'


class TopologyLauncher

  java_signature 'void main(String[])'
  def self.main(args)
    unless args.size > 0 
      puts("usage: redstorm {ruby topology class file path}")
      exit(1)
    end
    require args[0]
    clazz = camel_case(args[0].split('/').last.split('.').first)
    puts("redstorm launching #{clazz}")
    Object.module_eval(clazz).new.start
  end

  private 

  def self.camel_case(s)
    s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end