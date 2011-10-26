require 'java'

java_import 'backtype.storm.spout.SpoutOutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.topology.IRichSpout'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'

java_package 'redstorm.proxy'

class Spout
  java_implements IRichSpout

  java_signature 'IRichSpout (String real_spout_class_name)'
  def initialize(real_spout_class_name)
    @real_spout_class_name = real_spout_class_name
  end

  java_signature 'boolean isDistributed()'
  def isDistributed
    Object.module_eval(@real_spout_class_name).new.is_distributed
  end

  java_signature 'void open(Map, TopologyContext, SpoutOutputCollector)'
  def open(conf, context, collector)
    @real_spout = Object.module_eval(@real_spout_class_name).new
    @real_spout.open(conf, context, collector)
  end

  java_signature 'void close()'
  def close
    @real_spout.close if @real_spout.respond_to?(:close)
  end

  java_signature 'void nextTuple()'
  def nextTuple
    @real_spout.next_tuple
  end

  java_signature 'void ack(Object)'
  def ack(msgId)
    @real_spout.ack(msgId) if @real_spout.respond_to?(:close)
  end

  java_signature 'void fail(Object)'
  def fail(msgId)
    @real_spout.fail(msgId) if @real_spout.respond_to?(:close)
  end

  java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
  def declareOutputFields(declarer)
    Object.module_eval(@real_spout_class_name).new.declare_output_fields(declarer)
  end

end
