require 'java'

java_import 'storm.trident.operation.TridentCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'storm.trident.spout.IBatchSpout'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'
module Backtype
  java_import 'backtype.storm.Config'
end

java_package 'redstorm.proxy'

# the BatchSpout class is a proxy to the real batch spout to avoid having to deal with all the
# Java artifacts when creating a spout.
#
# The real batch spout class implementation must define these methods:
# - open(conf, context, collector)
# - emitBatch
# - getOutputFields
# - ack(batch_id)
#
# and optionnaly:
# - close
#

class BatchSpout
  java_implements IBatchSpout

  java_signature 'IBatchSpout (String base_class_path, String real_spout_class_name)'
  def initialize(base_class_path, real_spout_class_name)
    @real_spout = Object.module_eval(real_spout_class_name).new
  rescue NameError
    require base_class_path
    @real_spout = Object.module_eval(real_spout_class_name).new
  end

  java_signature 'void open(Map, TopologyContext)'
  def open(conf, context)
    @real_spout.open(conf, context)
  end

  java_signature 'void close()'
  def close
    @real_spout.close if @real_spout.respond_to?(:close)
  end

  java_signature 'void emitBatch(long, TridentCollector)'
  def emitBatch(batch_id, collector)
    @real_spout.emit_batch(batch_id, collector)
  end

  java_signature 'void ack(long)'
  def ack(batch_id)
    @real_spout.ack(batch_id)
  end

  java_signature 'Fields getOutputFields()'
  def getOutputFields
    @real_spout.get_output_fields()
  end

  java_signature 'Map<String, Object> getComponentConfiguration()'
  def getComponentConfiguration
    @real_spout.get_component_configuration
  end

end
