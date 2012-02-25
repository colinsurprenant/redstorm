require 'java'

java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.topology.IRichBolt'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'
java_import 'org.apache.log4j.Logger'

java_import 'org.apache.log4j.Logger'

java_package 'redstorm.proxy'

# the Bolt class is a proxy to the real bolt to avoid having to deal with all the
# Java artifacts when creating a bolt.
#
# The real bolt class implementation must define these methods:
# - prepare(conf, context, collector)
# - execute(tuple)
# - declare_output_fields
#
# and optionnaly:
# - cleanup
#
class Bolt
  java_implements IRichBolt

  java_signature 'IRichBolt (String base_class_path, String real_bolt_class_name)'
  def initialize(base_class_path, real_bolt_class_name)
    @real_bolt = Object.module_eval(real_bolt_class_name).new
  rescue NameError
    require base_class_path
    @real_bolt = Object.module_eval(real_bolt_class_name).new
  end

  java_signature 'void prepare(Map, TopologyContext, OutputCollector)'
  def prepare(conf, context, collector)
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
    @real_bolt.declare_output_fields(declarer)
  end
end
