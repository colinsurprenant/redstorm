java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.KafkaSpout'
java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.ZkHosts'

require 'red_storm'

# the KafkaTopology obviously requires a Kafka server running, you can ajust the
# host and port below.
#
# custom dependencies are required for the Kafka and Scala jars. put the following
# dependencies in the "ivy/topology_dependencies.xml" file in the root of your RedStorm project
# (in addition to the default dependencies, and any additions you may have added):

# <dependency org="org.scala-lang" name="scala-library" rev="2.10.1" conf="default" transitive="false"/>
# <dependency org="org.apache.kafka" name="kafka_2.10" rev="0.8.1.1" conf="default" transitive="false" />
# <dependency org="org.apache.storm" name="storm-kafka" rev="0.9.3" conf="default" transitive="true" />
# <dependency org="com.yammer.metrics" name="metrics-core" rev="2.2.0"/>
# <exclude org="org.slf4j" module="slf4j-log4j12"/>

class SplitStringBolt < RedStorm::DSL::Bolt
  on_receive {|tuple| String.from_java_bytes(tuple.value(:bytes)).split.map{|w| [w]}}

end

class KafkaTopology < RedStorm::DSL::Topology

  spout_config = SpoutConfig.new(
    ZkHosts.new("localhost:2181", "/brokers"),
    "test",        # topic to read from
    "/kafkaspout",  # Zookeeper root path to store the consumer offsets
    "someid"        # Zookeeper consumer id to store the consumer offsets
  )

  spout KafkaSpout, [spout_config]

  bolt SplitStringBolt do
    output_fields :word
    source KafkaSpout, :shuffle
    debug true
  end

  configure do |env|
    debug false
    max_task_parallelism 4
    num_workers 1
    max_spout_pending 1000
  end

  on_submit do |env|
    if env == :local
      sleep(120)
      cluster.shutdown
    end
  end
end