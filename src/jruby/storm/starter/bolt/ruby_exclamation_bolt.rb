require 'java'

java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.topology.IRichBolt'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'
java_import 'java.util.Map'

java_package 'storm.starter'

class RubyExclamationBolt
    java_implements IRichBolt

    java_signature 'void prepare(Map, TopologyContext, OutputCollector)'
    def prepare(conf, context, collector)
      @collector = collector
    end

    java_signature 'void execute(Tuple)'
    def execute(tuple)
      @collector.emit(tuple, Values.new(tuple.getString(0) + "!!!"))
      @collector.ack(tuple)
    end

    java_signature 'void cleanup()'
    def cleanup
    end

    java_signature 'void declareOutputFields(OutputFieldsDeclarer)'
    def declareOutputFields(declarer)
      declarer.declare(Fields.new("word"))
    end

  end
