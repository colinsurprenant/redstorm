java_import 'backtype.storm.testing.TestWordSpout'

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
  def start
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
