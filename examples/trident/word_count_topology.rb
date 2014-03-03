require 'red_storm'
require 'json'

java_import "backtype.storm.LocalCluster"
java_import "backtype.storm.LocalDRPC"
java_import "backtype.storm.StormSubmitter"
java_import "backtype.storm.generated.StormTopology"
java_import "backtype.storm.tuple.Fields"
java_import "backtype.storm.tuple.Values"
java_import "storm.trident.TridentState"
java_import "storm.trident.TridentTopology"
java_import "storm.trident.operation.BaseFunction"
java_import "storm.trident.operation.TridentCollector"
java_import "storm.trident.operation.builtin.Count"
java_import "storm.trident.operation.builtin.FilterNull"
java_import "storm.trident.operation.builtin.MapGet"
java_import "storm.trident.operation.builtin.Sum"
java_import "storm.trident.testing.FixedBatchSpout"
java_import "storm.trident.testing.MemoryMapState"
java_import "storm.trident.tuple.TridentTuple"

java_import 'redstorm.storm.jruby.JRubyTridentFunction'

REQUIRE_PATH = Pathname.new(__FILE__).relative_path_from(Pathname.new(RedStorm::BASE_PATH)).to_s

# Usage:
#
# Local mode:
#
# $ redstorm install
# $ redstorm examples
# $ restorm local examples/trident/word_count_topology.rb
#
# Cluster mode:
#
# $ redstorm install
# $ redstorm examples
# $ redstorm jar examples
# $ redstorm cluster examples/trident/word_count_topology.rb
#
#  After submission, wait a bit for topology to startup and launch the drpc query example:
#  Edit word_count_query.rb to set the host/port of your cluster drpc daemon.
#
# $ redstorm local examples/trident/word_count_query.rb

module Examples
  class TridentSplit

    def execute(tuple, collector)
      tuple[0].split(" ").each do |word|
        collector.emit(Values.new(word))
      end
    end

    def prepare(conf, context); end
    def cleanup;end
  end

  class TridentWordCountTopology
    RedStorm::Configuration.topology_class = self

    def build_topology(local_drpc)
      spout = FixedBatchSpout.new(
        Fields.new("sentence"), 3,
        Values.new("the cow jumped over the moon"),
        Values.new("the man went to the store and bought some candy"),
        Values.new("four score and seven years ago"),
        Values.new("how many apples can you eat"),
        Values.new("to be or not to be the person")
      )
      spout.cycle = true

      topology = TridentTopology.new

      stream = topology.new_stream("spout1", spout)
        .parallelism_hint(3)
        .each(
          Fields.new("sentence"),
          JRubyTridentFunction.new(REQUIRE_PATH, "Examples::TridentSplit"),
          Fields.new("word")
        )
        .groupBy(
          Fields.new("word")
        )
        .persistentAggregate(
          MemoryMapState::Factory.new,
          Count.new,
          Fields.new("count")
        )
        .parallelism_hint(3)

      # topology.newDRPCStream("words", drpc)
      topology.newDRPCStream("words", local_drpc)
        .each(
          Fields.new("args"),
          JRubyTridentFunction.new(REQUIRE_PATH, "Examples::TridentSplit"),
          Fields.new("word")
        )
        .groupBy(
          Fields.new("word")
        )
        .stateQuery(
          stream,
          Fields.new("word"),
          MapGet.new,
          Fields.new("count")
        )
        .each(
          Fields.new("count"),
          FilterNull.new
        )
        .aggregate(
          Fields.new("count"),
          Sum.new,
          Fields.new("sum")
        )

      topology.build
    end

    def display_drpc(client)
      loop do
        sleep(2)

        json_result = client.execute("words", "cat the dog jumped")
        puts("DRPC execute=#{JSON.parse(json_result)[0][0]}")
      end
    end

    def start(env)
      conf = Backtype::Config.new
      conf.debug = false
      conf.max_spout_pending = 20

      case env
      when :local
        local_drpc = LocalDRPC.new
        submitter = LocalCluster.new
        conf.num_workers = 1 # set to 1 in local, see https://issues.apache.org/jira/browse/STORM-113
      when :cluster
        local_drpc = nil
        submitter = StormSubmitter
        conf.put("drpc.servers", ["localhost"])
        conf.num_workers = 3
      end

      submitter.submit_topology("trident_word_count", conf, build_topology(local_drpc));

      display_drpc(local_drpc) if local_drpc
    end
  end

end
