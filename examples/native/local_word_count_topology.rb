require 'lib/red_storm'
require 'examples/native/random_sentence_spout'
require 'examples/native/split_sentence_bolt'
require 'examples/native/word_count_bolt'


module Examples
  class LocalWordCountTopology
    RedStorm::Configuration.topology_class = self

    def start(base_class_path, env)
      builder = TopologyBuilder.new
      builder.setSpout('RandomSentenceSpout', JRubySpout.new(base_class_path, "RedStorm::Examples::RandomSentenceSpout", []), 5)
      builder.setBolt('SplitSentenceBolt', JRubyBolt.new(base_class_path, "RedStorm::Examples::SplitSentenceBolt", []), 8).shuffleGrouping('RandomSentenceSpout')
      builder.setBolt('WordCountBolt', JRubyBolt.new(base_class_path, "RedStorm::Examples::WordCountBolt", []), 12).fieldsGrouping('SplitSentenceBolt', Fields.new("word"))

      conf = Backtype::Config.new
      conf.setDebug(true)
      conf.setMaxTaskParallelism(3)

      cluster = LocalCluster.new
      cluster.submitTopology("word_count", conf, builder.createTopology)
      sleep(5)
      cluster.shutdown
    end
  end
end
