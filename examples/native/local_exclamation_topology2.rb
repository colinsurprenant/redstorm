java_import 'backtype.storm.testing.TestWordSpout'

require 'lib/red_storm'

module RedStorm
  module Examples
    class ExclamationBolt2
      def prepare(conf, context, collector)
        @collector = collector
      end

      def execute(tuple)
        @collector.emit(tuple, Values.new("!#{tuple.getString(0)}!"))
        @collector.ack(tuple)
      end

      def get_component_configuration
      end

      def declare_output_fields(declarer)
        declarer.declare(Fields.new("word"))
      end
    end

    # this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

    class LocalExclamationTopology2
      RedStorm::Configuration.topology_class = self

      def start(base_class_path, env)
        builder = TopologyBuilder.new

        builder.setSpout('TestWordSpout', TestWordSpout.new, 10)
        builder.setBolt('ExclamationBolt21', JRubyBolt.new(base_class_path, "RedStorm::Examples::ExclamationBolt2", []), 3).shuffleGrouping('TestWordSpout')
        builder.setBolt('ExclamationBolt22', JRubyBolt.new(base_class_path, "RedStorm::Examples::ExclamationBolt2", []), 2).shuffleGrouping('ExclamationBolt21')

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
