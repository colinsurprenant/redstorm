require 'red_storm'
java_import 'storm.kafka.KafkaConfig'
java_import 'storm.kafka.SpoutConfig'
java_import 'storm.kafka.StringScheme'
java_import 'storm.kafka.KafkaSpout'


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