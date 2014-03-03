require "red_storm"
require "json"

java_import "backtype.storm.utils.DRPCClient"

# Usage:
#
# This is a DRPC client that will query a Storm cluster trident drpc topology.
# See the trident word_count_topology.rb for runnnig the drpc topology.
#
# Edit the host and port below.

module Example

  # this is not a topology, the redstorm topology_launcher will launch any class with the
  # start method in the correct storm environment

  class TridentWordCountQuery
    RedStorm::Configuration.topology_class = self

    def start(env)
      puts("TridentWordCountQuery starting")

      client = DRPCClient.new("localhost", 3772)
      loop do
        json_result = client.execute("words", "cat the dog jumped")
        puts("DRPC execute=#{JSON.parse(json_result)[0][0]}")

        sleep(2)
      end
    end
  end
end