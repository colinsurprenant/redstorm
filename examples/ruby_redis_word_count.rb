require 'java'
require 'rubygems'
require 'redis'
require 'thread'

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

# RubyRedisWordSpout reads the Redis queue "test" on localhost:6379 
# and emits each word items pop'ed from the queue.
class RubyRedisWordSpout

  def is_distributed
    false
  end

  def open(conf, context, collector)
    @collector = collector

    @q = Queue.new
    @redis_reader = detach_redis_reader
  end
  
  def next_tuple
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

  java_signature 'void main(String[])'
  def self.main(args)
    builder = TopologyBuilder.new
    builder.setSpout(1, JRubySpout.new("RubyRedisWordSpout"), 1)
    builder.setBolt(2, JRubyBolt.new("RubyRedisWordCount"), 3).fieldsGrouping(1, Fields.new("word"))

    conf = Config.new
    conf.setDebug(true)
    conf.setMaxTaskParallelism(3)

    cluster = LocalCluster.new
    cluster.submitTopology("redis-word-count", conf, builder.createTopology)
    sleep(600)
    cluster.shutdown
  end
end