require 'java'

java_import 'backtype.storm.coordination.BatchOutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.coordination.IBatchBolt'
java_import 'backtype.storm.transactional.ICommitter'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Tuple'
java_import 'java.util.Map'

module Backtype
  java_import 'backtype.storm.Config'
end

java_package 'redstorm.proxy'

class BatchCommitterBolt
  java_implements 'ICommitter, IBatchBolt'

  java_signature 'IBatchCommitterBolt (String base_class_path, String real_bolt_class_name)'
  def initialize(base_class_path, real_bolt_class_name)
    @real_bolt = Object.module_eval(real_bolt_class_name).new
  rescue NameError
    require base_class_path
    @real_bolt = Object.module_eval(real_bolt_class_name).new
  end

  java_signature 'void prepare(Map, TopologyContext, BatchOutputCollector, Object)'
  def prepare(conf, context, collector, id)
    @real_bolt.prepare(conf, context, collector, id)
  end

  java_signature 'void execute(Tuple)'
  def execute(tuple)
    @real_bolt.execute(tuple)
  end

  java_signature 'void finishBatch()'
  def finishBatch
    @real_bolt.finish_batch if @real_bolt.respond_to?(:finish_batch)
  end

  java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
  def declareOutputFields(declarer)
    @real_bolt.declare_output_fields(declarer)
  end

  java_signature 'Map<String, Object> getComponentConfiguration()'
  def getComponentConfiguration
    @real_bolt.get_component_configuration
  end
end
