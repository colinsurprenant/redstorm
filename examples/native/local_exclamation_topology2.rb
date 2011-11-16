java_import 'backtype.storm.testing.TestWordSpout'

class ExclamationBolt2
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

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

class LocalExclamationTopology2
  def start(base_class_path, env)
    builder = TopologyBuilder.new
    
    builder.setSpout(1, TestWordSpout.new, 10)     
    builder.setBolt(2, JRubyBolt.new(base_class_path, "ExclamationBolt2"), 3).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new(base_class_path, "ExclamationBolt2"), 2).shuffleGrouping(2)
            
    conf = Config.new
    conf.setDebug(true)
    
    cluster = LocalCluster.new
    cluster.submitTopology("test", conf, builder.createTopology)
    sleep(5)
    cluster.killTopology("test")
    cluster.shutdown
  end
end
