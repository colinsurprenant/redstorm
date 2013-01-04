java_import 'backtype.storm.testing.TestWordSpout'

require 'lib/red_storm'
require 'examples/native/exclamation_bolt'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

module RedStorm
  module Examples
    class LocalExclamationTopology
      RedStorm::Configuration.topology_class = self

      def start(base_class_path, env)
        builder = TopologyBuilder.new
        
        builder.setSpout('TestWordSpout', TestWordSpout.new, 10)     
        builder.setBolt('ExclamationBolt1', JRubyBolt.new(base_class_path, 'RedStorm::Examples::ExclamationBolt'), 3).shuffleGrouping('TestWordSpout')
        builder.setBolt('ExclamationBolt2', JRubyBolt.new(base_class_path, 'RedStorm::Examples::ExclamationBolt'), 3).shuffleGrouping('ExclamationBolt1')
                
        conf = Backtype::Config.new
        conf.setDebug(true)
        
        cluster = LocalCluster.new
        cluster.submitTopology("exclamation", conf, builder.createTopology)
        sleep(5)
        cluster.killTopology("exclamation")
        cluster.shutdown
      end
    end
  end
end