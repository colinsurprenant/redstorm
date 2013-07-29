require 'red_storm'
require 'examples/dsl/word_count_bolt'
require 'redis'
require 'thread'

module RedStorm
  module Examples

    # RedisWordSpout reads the Redis queue "test" on localhost:6379
    # and emits each word items pop'ed from the queue.

    class RedisWordSpout < DSL::Spout
      output_fields :word

      on_send {@q.pop.to_s if @q.size > 0}

      on_init do
        @q = Queue.new
        @redis_reader = detach_redis_reader
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

    class RedisWordCountTopology < DSL::Topology
      spout RedisWordSpout

      bolt WordCountBolt, :parallelism => 2 do
        debug true
        source RedisWordSpout, :fields => ["word"]
      end

      configure do |env|
        debug false
        max_task_parallelism 2
        num_workers 1
        max_spout_pending 1000
      end
    end
  end
end