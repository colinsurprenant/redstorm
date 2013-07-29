java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.KafkaSpout'
java_import 'storm.kafka.KafkaConfig'

require 'red_storm'

# the KafkaTopology obviously requires a Kafka server running, you can ajust the
# host and port below.
#
# custom dependencies are required for the Kafka and Scala jars. put the following
# dependencies in the "ivy/topology_dependencies.xml" file in the root of your RedStorm project:
#
# <?xml version="1.0"?>
# <ivy-module version="2.0" xmlns:m="http://ant.apache.org/ivy/maven">
#   <info organisation="redstorm" module="topology-deps"/>
#   <dependencies>
#     <dependency org="org.jruby" name="jruby-core" rev="1.7.4" conf="default" transitive="true"/>

#     <dependency org="org.scala-lang" name="scala-library" rev="2.9.2" conf="default" transitive="false"/>
#     <dependency org="com.twitter" name="kafka_2.9.2" rev="0.7.0" conf="default" transitive="false"/>
#     <dependency org="storm" name="storm-kafka" rev="0.9.0-wip16a-scala292" conf="default" transitive="true"/>

#     <!-- explicitely specify jffi to also fetch the native jar. make sure to update jffi version matching jruby-core version -->
#     <!-- this is the only way I found using Ivy to fetch the native jar -->
#     <dependency org="com.github.jnr" name="jffi" rev="1.2.5" conf="default" transitive="true">
#       <artifact name="jffi" type="jar" />
#       <artifact name="jffi" type="jar" m:classifier="native"/>
#     </dependency>

#   </dependencies>
# </ivy-module>

class SplitStringBolt < RedStorm::DSL::Bolt
  on_receive {|tuple| tuple[0].split.map{|w| [w]}}
end

class KafkaTopology < RedStorm::DSL::Topology

  spout_config = SpoutConfig.new(
    KafkaConfig::ZkHosts.new("localhost:2181", "/brokers"),
    "words",        # topic to read from
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
      sleep(10)
      cluster.shutdown
    end
  end
end