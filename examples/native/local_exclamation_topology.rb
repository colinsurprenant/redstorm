java_import 'backtype.storm.testing.TestWordSpout'
require 'examples/exclamation_bolt'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

class LocalExclamationTopology
  def start(base_class_path)
    builder = TopologyBuilder.new
    
    builder.setSpout(1, TestWordSpout.new, 10)     
    builder.setBolt(2, JRubyBolt.new(base_class_path, "ExclamationBolt"), 3).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new(base_class_path, "ExclamationBolt"), 2).shuffleGrouping(2)
            
    conf = Config.new
    conf.setDebug(true)
    
    cluster = LocalCluster.new
    cluster.submitTopology("test", conf, builder.createTopology)
    sleep(5)
    cluster.killTopology("test")
    cluster.shutdown
  end
end
