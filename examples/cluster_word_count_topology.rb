class RubyRandomSentenceSpout
  attr_reader :is_distributed

  def initialize
    @is_distributed = true
    @sentences = [
      "the cow jumped over the moon",
      "an apple a day keeps the doctor away",
      "four score and seven years ago",
      "snow white and the seven dwarfs",
      "i am at two with nature"
    ]
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


class ClusterWordCountTopology
  def start(base_class_path)
    builder = TopologyBuilder.new
    builder.setSpout(1, JRubySpout.new(base_class_path, "RubyRandomSentenceSpout"), 5)
    builder.setBolt(2, JRubyBolt.new(base_class_path, "RubySplitSentence"), 4).shuffleGrouping(1)
    builder.setBolt(3, JRubyBolt.new(base_class_path, "RubyWordCount"), 4).fieldsGrouping(2, Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setNumWorkers(20);
    conf.setMaxSpoutPending(1000);
    StormSubmitter.submitTopology("word-count", conf, builder.createTopology);
  end
end