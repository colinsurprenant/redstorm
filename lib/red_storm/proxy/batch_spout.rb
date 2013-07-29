require 'java'

java_import 'backtype.storm.task.TopologyContext'
java_import 'storm.trident.operation.TridentCollector'
java_import 'storm.trident.spout.IBatchSpout'
java_import 'backtype.storm.tuple.Fields'
java_import 'java.util.Map'

java_package 'redstorm.proxy'

# the Spout class is a proxy to the real spout to avoid having to deal with all the
# Java artifacts when creating a spout.

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
    @real_spout.open(conf, context) if @real_spout.respond_to?(:open)
  end

  java_signature 'void emitBatch(long, TridentCollector)'
  def emitBatch(batch_id, collector)
  	@real_spout.emit_batch(batch_id, collector)
  end

  java_signature 'void close()'
  def close
    @real_spout.close if @real_spout.respond_to?(:close)
  end

  java_signature 'void ack(long)'
  def ack(batch_id)
    @real_spout.ack(batch_id) if @real_spout.respond_to?(:ack)
  end

  java_signature 'Fields getOutputFields()'
  def getOutputFields()
    @real_spout.get_output_fields
  end

  java_signature 'Map<String, Object> getComponentConfiguration()'
  def getComponentConfiguration
    @real_spout.get_component_configuration
  end

end
