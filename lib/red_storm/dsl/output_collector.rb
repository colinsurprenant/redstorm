require 'java'
java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.tuple.Tuple'

# make alias methods to specific signatures to avoid selection overhead for heavily overloaded method
class OutputCollector
  java_alias :emit_tuple, :emit, [java.lang.Class.for_name("java.util.List")]
  java_alias :emit_anchor_tuple, :emit, [Tuple.java_class, java.lang.Class.for_name("java.util.List")]
  java_alias :emit_tuple_stream, :emit, [
    java.lang.String,
    java.lang.Class.for_name("java.util.List")
  ]
  java_alias :emit_anchor_tuple_stream, :emit, [
    java.lang.String,
    Tuple.java_class,
    java.lang.Class.for_name("java.util.List")
  ]
end
