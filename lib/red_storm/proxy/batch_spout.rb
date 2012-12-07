require 'java'


java_import 'java.util.Map'

java_import 'backtype.storm.task.TopologyContext'

java_import 'storm.trident.operation.TridentCollector'

java_import 'backtype.storm.tuple.Fields'

java_import 'storm.trident.spout.IBatchSpout'


module Backtype
  java_import 'backtype.storm.Config'
end

java_package 'redstorm.proxy'

class BatchSpout
  java_implements IBatchSpout

  java_signature 'IBatchSpout (String base_class_path, String real_class_name)'
  def initialize(base_class_path, real_class_name)
    @real = Object.module_eval(real_class_name).new
  rescue NameError
    require base_class_path
    @real = Object.module_eval(real_class_name).new
  end

  java_signature 'void open(Map, TopologyContext)'
  def open(_map, _topology_context)
    @real.open(Map, TopologyContext)
  end

  java_signature 'void close()'
  def close()
    @real.close()
  end

  java_signature 'void ack(long)'
  def ack(_long)
    @real.ack(long)
  end

  java_signature 'void emit_batch(long, TridentCollector)'
  def emit_batch(_long, _trident_collector)
    @real.emit_batch(long, TridentCollector)
  end

  java_signature 'Map get_component_configuration()'
  def get_component_configuration()
    @real.get_component_configuration()
  end

  java_signature 'Fields get_output_fields()'
  def get_output_fields()
    @real.get_output_fields()
  end


end
