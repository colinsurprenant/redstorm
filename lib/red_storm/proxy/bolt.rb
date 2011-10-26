require 'java'

java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.topology.IRichBolt'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'

java_package 'redstorm.proxy'

class Bolt
  java_implements IRichBolt

  java_signature 'IRichBolt (String real_bolt_class_name)'
  def initialize(real_bolt_class_name)
    @real_bolt_class_name = real_bolt_class_name
  end

  java_signature 'void prepare(Map, TopologyContext, OutputCollector)'
  def prepare(conf, context, collector)
    @real_bolt = Object.module_eval(@real_bolt_class_name).new
    @real_bolt.prepare(conf, context, collector)
  end

  java_signature 'void execute(Tuple)'
  def execute(tuple)
    @real_bolt.execute(tuple)
  end

  java_signature 'void cleanup()'
  def cleanup
    @real_bolt.cleanup if @real_bolt.respond_to?(:cleanup)
  end

  java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
  def declareOutputFields(declarer)
    Object.module_eval(@real_bolt_class_name).new.declare_output_fields(declarer)
  end

end
