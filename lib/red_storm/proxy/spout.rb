require 'java'

java_import 'backtype.storm.spout.SpoutOutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.topology.IRichSpout'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'
java_import 'org.apache.log4j.Logger'

java_package 'redstorm.proxy'

# the Spout class is a proxy to the real spout to avoid having to deal with all the
# Java artifacts when creating a spout.
#
# The real spout class implementation must define these methods:
# - open(conf, context, collector)
# - next_tuple
# - is_distributed
# - declare_output_fields
#
# and optionnaly:
# - ack(msg_id)
# - fail(msg_id)
# - close
#

class Spout
  java_implements IRichSpout

  java_signature 'IRichSpout (String base_class_path, String real_spout_class_name)'
  def initialize(base_class_path, real_spout_class_name)
    @real_spout = Object.module_eval(real_spout_class_name).new
  rescue NameError
    require base_class_path
    @real_spout = Object.module_eval(real_spout_class_name).new
  end

  java_signature 'boolean isDistributed()'
  def isDistributed
    @real_spout.respond_to?(:is_distributed) ? @real_spout.is_distributed : false
  end

  java_signature 'void open(Map, TopologyContext, SpoutOutputCollector)'
  def open(conf, context, collector)
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
  def ack(msg_id)
    @real_spout.ack(msg_id) if @real_spout.respond_to?(:ack)
  end

  java_signature 'void fail(Object)'
  def fail(msg_id)
    @real_spout.fail(msg_id) if @real_spout.respond_to?(:fail)
  end

  java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
  def declareOutputFields(declarer)
    @real_spout.declare_output_fields(declarer)
  end
end
