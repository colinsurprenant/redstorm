require 'java'

java_import 'backtype.storm.Config'
java_import 'backtype.storm.LocalCluster'
java_import 'backtype.storm.task.OutputCollector'
java_import 'backtype.storm.task.TopologyContext'
java_import 'backtype.storm.testing.TestWordSpout'
java_import 'backtype.storm.topology.IRichBolt'
java_import 'backtype.storm.topology.OutputFieldsDeclarer'
java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.Values'
java_import 'backtype.storm.utils.Utils'
java_import 'java.util.Map'

java_import 'backtype.storm.jruby.JRubyBolt'
java_import 'backtype.storm.jruby.JRubySpout'


class RubyRandomSentenceSpout
  def initialize
    @sentences = [
      "the cow jumped over the moon",
      "an apple a day keeps the doctor away",
      "four score and seven years ago",
      "snow white and the seven dwarfs",
      "i am at two with nature"
    ]
  end 

  def is_distributed
    true
  end

  def open(conf, context, collector)
    @collector = collector
  end
  
  def next_tuple
    @collector.emit(Values.new(@sentences[rand(@sentences.length)]))
  end

  def declare_output_fields(declarer)
    declarer.declare(Fields.new("word"))
  end
end

class RubySplitSentence
  def prepare(conf, context, collector)
    @collector = collector
  end

  def execute(tuple)
    tuple.getString(0).split(" ").each {|w| @collector.emit(Values.new(w)) }
  end

  def declare_output_fields(declarer)
    declarer.declare(Fields.new("word"))
  end
end

class RubyWordCount
  def initialize
    @counts = Hash.new{|h, k| h[k] = 0}
  end

  def prepare(conf, context, collector)
    @collector = collector
  end

  def execute(tuple)
    word = tuple.getString(0)
    @counts[word] += 1
    @collector.emit(Values.new(word, @counts[word]))
  end

  def declare_output_fields(declarer)
    declarer.declare(Fields.new("word", "count"))
  end
end


class RubyWordCountTopology

  java_signature 'void main(String[])'
  def self.main(args)
    builder = TopologyBuilder.new
    builder.setSpout(1, JRubySpout.new("RubyRandomSentenceSpout"), 5)
    builder.setBolt(2, JRubyBolt.new("RubySplitSentence"), 8).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new("RubyWordCount"), 12).fieldsGrouping(2, Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setMaxTaskParallelism(3)

    cluster = LocalCluster.new
    cluster.submitTopology("word-count", conf, builder.createTopology)
    sleep(5)
    cluster.shutdown
  end
end