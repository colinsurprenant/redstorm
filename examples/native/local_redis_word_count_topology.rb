require 'redis'
require 'thread'
require 'examples/native/word_count_bolt'

# RedisWordSpout reads the Redis queue "test" on localhost:6379 
# and emits each word items pop'ed from the queue.
class RedisWordSpout
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

class LocalRedisWordCountTopology
  def start(base_class_path, env)
    builder = TopologyBuilder.new
    builder.setSpout('1', JRubySpout.new(base_class_path, "RedisWordSpout"), 1)
    builder.setBolt('2', JRubyBolt.new(base_class_path, "WordCountBolt"), 3).fieldsGrouping('1', Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setMaxTaskParallelism(3)

    cluster = LocalCluster.new
    cluster.submitTopology("redis-word-count", conf, builder.createTopology)
    sleep(600)
    cluster.shutdown
  end
end