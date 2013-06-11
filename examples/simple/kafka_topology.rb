java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.StringScheme'
java_import 'storm.kafka.KafkaSpout'

require 'red_storm'

# the KafkaTopology obviously requires a Kafka server running, you can ajust the
# host and port below.
#
# custom dependencies are required for the Kafka and Scala jars. put the following
# dependencies in the "ivy/topology_dependencies.xml" file in the root of your RedStorm project:
#
# <?xml version="1.0"?>
# <ivy-module version="2.0">
#   <info organisation="redstorm" module="topology-deps"/>
#   <dependencies>
#     <dependency org="org.jruby" name="jruby-core" rev="1.7.3" conf="default" transitive="true"/>
#     <dependency org="org.scala-lang" name="scala-library" rev="2.8.0" conf="default" transitive="false"/>
#     <dependency org="storm" name="kafka" rev="0.7.0-incubating" conf="default" transitive="false"/>
#     <dependency org="storm" name="storm-kafka" rev="0.8.0-wip4" conf="default" transitive="false"/>
#   </dependencies>
# </ivy-module>

class KafkaTopology < RedStorm::SimpleTopology
  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new("localhost:2181", "/brokers"),
    "words",        # topic to read from
    "/kafkastorm",  # Zookeeper root path to store the consumer offsets
    "discovery"     # Zookeeper consumer id to store the consumer offsets
  )
  spout_config.scheme = StringScheme.new

  class SplitStringBolt < RedStorm::SimpleBolt
    on_receive {|tuple| tuple.getString(0).split.map{|w| [w]}}
  end

  spout KafkaSpout, [spout_config]

  bolt SplitStringBolt do
    output_fields :word
    source KafkaSpout, :shuffle
  end

  configure do |env|
    debug true
  end

  on_submit do |env|
    if env == :local
      sleep(10)
      cluster.shutdown
    end
  end
end