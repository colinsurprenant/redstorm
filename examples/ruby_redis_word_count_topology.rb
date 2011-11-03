require 'redis'
require 'thread'

# RubyRedisWordSpout reads the Redis queue "test" on localhost:6379 
# and emits each word items pop'ed from the queue.
class RubyRedisWordSpout
  def open(conf, context, collector)
    @collector = collector
    @q = Queue.new
    @redis_reader = detach_redis_reader
  end
  
  def next_tuple
    # per doc nextTuple should not block, and sleep a bit when there's no data to process.
    if @q.size > 0
      @collector.emit(Values.new(@q.pop))
    else
      sleep(0.1)
    end
  end

  def declare_output_fields(declarer)
    declarer.declare(Fields.new("word"))
  end

  private

  def detach_redis_reader
    Thread.new do
      Thread.current.abort_on_exception = true

      redis = Redis.new(:host => "localhost", :port => 6379)
      loop do
        if data = redis.blpop("test", 0)
          @q << data[1]
        end
      end
    end
  end
end

class RubyRedisWordCount
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

class RubyRedisWordCountTopology
  def start(base_class_path)
    builder = TopologyBuilder.new
    builder.setSpout(1, JRubySpout.new(base_class_path, "RubyRedisWordSpout"), 1)
    builder.setBolt(2, JRubyBolt.new(base_class_path, "RubyRedisWordCount"), 3).fieldsGrouping(1, Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setMaxTaskParallelism(3)

    cluster = LocalCluster.new
    cluster.submitTopology("redis-word-count", conf, builder.createTopology)
    sleep(600)
    cluster.shutdown
  end
end