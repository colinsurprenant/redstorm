require 'java'


java_import 'storm.trident.tuple.TridentTuple'

java_import 'storm.trident.operation.TridentCollector'

java_import 'java.util.Map'

java_import 'storm.trident.operation.TridentOperationContext'

java_import 'storm.trident.operation.Function'


module Backtype
  java_import 'backtype.storm.Config'
end

java_package 'redstorm.proxy'

class ProxyFunction
  java_implements Function

  java_signature 'Function (String base_class_path, String real_class_name)'
  def initialize(base_class_path, real_class_name)
    @real = Object.module_eval(real_class_name).new
  rescue NameError
    require base_class_path
    @real = Object.module_eval(real_class_name).new
  end

  java_signature 'void execute(TridentTuple, TridentCollector)'
  def execute(_trident_tuple, _trident_collector)
    @real.execute(_trident_tuple, _trident_collector)
  end

  java_signature 'void cleanup()'
  def cleanup()
    @real.cleanup()
  end

  java_signature 'void prepare(Map, TridentOperationContext)'
  def prepare(_map, _trident_operation_context)
    @real.prepare(_map, _trident_operation_context)
  end


end
