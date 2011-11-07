class WordCountBolt
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
