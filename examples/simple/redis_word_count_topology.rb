require 'rubygems' # needed for remote cluster exec where TopolyLauncher require rubygems is not called
require 'red_storm'
require 'bundler/setup'

require 'redis'
require 'thread'
require 'examples/simple/word_count_bolt'


module RedStorm
  module Examples

    # RedisWordSpout reads the Redis queue "test" on localhost:6379 
    # and emits each word items pop'ed from the queue.

    class RedisWordSpout < RedStorm::SimpleSpout
      output_fields :word

      on_send {@q.pop if @q.size > 0}

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

    class RedisWordCountTopology < RedStorm::SimpleTopology
      spout RedisWordSpout
          
      bolt WordCountBolt, :parallelism => 3 do
        source RedisWordSpout, :fields => ["word"]
      end

      configure do |env|
        debug true
        case env
        when :local
          max_task_parallelism 3
        when :cluster
          num_workers 20
          max_spout_pending(1000);
        end
      end
    end
  end
end