require 'java'
java_import 'backtype.storm.task.OutputCollector'

# make alias methods to specific signatures to avoid selection overhead for heavily overloaded method
class OutputCollector
  java_alias :emit_tuple, :emit, [java.lang.Class.for_name("java.util.List")]
  java_alias :emit_anchor_tuple, :emit, [java.lang.Class.for_name("backtype.storm.tuple.Tuple"), java.lang.Class.for_name("java.util.List")]
end
