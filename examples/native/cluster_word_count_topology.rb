require 'red_storm'
require 'examples/native/random_sentence_spout'
require 'examples/native/split_sentence_bolt'
require 'examples/native/word_count_bolt'

module RedStorm
  module Examples
    class ClusterWordCountTopology
      RedStorm::Configuration.topology_class = self

      def start(base_class_path, env)
        builder = TopologyBuilder.new
        builder.setSpout('RandomSentenceSpout', JRubySpout.new(base_class_path, "RedStorm::Examples::RandomSentenceSpout", []), 1)
        builder.setBolt('SplitSentenceBolt', JRubyBolt.new(base_class_path, "RedStorm::Examples::SplitSentenceBolt", []), 2).shuffleGrouping('RandomSentenceSpout')
        builder.setBolt('WordCountBolt', JRubyBolt.new(base_class_path, "RedStorm::Examples::WordCountBolt", []), 2).fieldsGrouping('SplitSentenceBolt', Fields.new("word"))

        conf = Backtype::Config.new
        conf.setDebug(true)
        conf.setNumWorkers(4);
        conf.setMaxSpoutPending(1000);
        StormSubmitter.submitTopology("word_count", conf, builder.createTopology);
      end
    end
  end
end
