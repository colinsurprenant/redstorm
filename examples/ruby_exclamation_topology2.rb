require 'java'

java_import 'backtype.storm.Config'
java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.testing.TestWordSpout'
java_import 'backtype.storm.topology.IRichBolt'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'
java_import 'backtype.storm.utils.Utils'
java_import 'java.util.Map'

java_import 'backtype.storm.jruby.JRubyBolt'

class RubyExclamationBolt2

  def prepare(conf, context, collector)
    @collector = collector
  end

  def execute(tuple)
    @collector.emit(tuple, Values.new(tuple.getString(0) + "!!!"))
    @collector.ack(tuple)
  end

  def declare_output_fields(declarer)
    declarer.declare(Fields.new("word"))
  end

end

class RubyExclamationTopology2

  java_signature 'void main(String[])'
  def self.main(args)
    builder = TopologyBuilder.new
    
    builder.setSpout(1, TestWordSpout.new, 10)     
    builder.setBolt(2, JRubyBolt.new("RubyExclamationBolt2"), 3).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new("RubyExclamationBolt2"), 2).shuffleGrouping(2)
            
    conf = Config.new
    conf.setDebug(true)
    
    cluster = LocalCluster.new
    cluster.submitTopology("test", conf, builder.createTopology)
    sleep(5)
    cluster.killTopology("test")
    cluster.shutdown
  end

end
