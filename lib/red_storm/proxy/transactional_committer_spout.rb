require 'java'

java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.transactional.ITransactionalSpout'
java_import 'backtype.storm.transactional.ICommitterTransactionalSpout'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'java.util.Map'
java_import 'org.apache.log4j.Logger'
module Backtype
  java_import 'backtype.storm.Config'
end

java_package 'redstorm.proxy'


class TransactionalCommitterSpout
  java_implements 'ICommitterTransactionalSpout'

  java_signature 'ICommitterTransactionalSpout (String base_class_path, String real_spout_class_name)'
  def initialize(base_class_path, real_spout_class_name)
    @real_spout = Object.module_eval(real_spout_class_name).new
  rescue NameError
    require base_class_path
    @real_spout = Object.module_eval(real_spout_class_name).new
  end

  java_signature 'ICommitterTransactionalSpout.Emitter getEmitter(Map, TopologyContext)'
  def getEmitter(conf, context)
    @real_spout.get_emitter(conf, context)
  end

  java_signature 'Coordinator getCoordinator(Map, TopologyContext)'
  def getCoordinator(conf, context)
    @real_spout.get_coordinator(conf, context)
  end

  java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
  def declareOutputFields(declarer)
    @real_spout.declare_output_fields(declarer)
  end

  java_signature 'Map<String, Object> getComponentConfiguration()'
  def getComponentConfiguration
    @real_spout.get_component_configuration
  end

end