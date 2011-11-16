require 'examples/native/random_sentence_spout'
require 'examples/native/split_sentence_bolt'
require 'examples/native/word_count_bolt'

class ClusterWordCountTopology
  def start(base_class_path, env)
    builder = TopologyBuilder.new
    builder.setSpout(1, JRubySpout.new(base_class_path, "RandomSentenceSpout"), 5)
    builder.setBolt(2, JRubyBolt.new(base_class_path, "SplitSentenceBolt"), 4).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new(base_class_path, "WordCountBolt"), 4).fieldsGrouping(2, Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setNumWorkers(20);
    conf.setMaxSpoutPending(1000);
    StormSubmitter.submitTopology("word-count", conf, builder.createTopology);
  end
end