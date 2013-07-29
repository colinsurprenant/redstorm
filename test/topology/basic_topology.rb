require 'red_storm'
require 'thread'
require 'redis'

class SingleTupleSpout < RedStorm::DSL::Spout
  output_fields :string

  on_init do
    @q = Queue.new
    @q << "SUCCESS"
  end

  on_send do
    # avoid putting the thread to sleep endlessly on @q.pop which will prevent local cluster.shutdown
    sleep(1)
    @q.pop unless @q.empty?
  end
end

class RedisPushBolt < RedStorm::DSL::Bolt
  on_init {@redis = Redis.new(:host => "localhost", :port => 6379)}

  on_receive :emit => false do |tuple|
    data = tuple[0].to_s
    @redis.lpush(File.basename(__FILE__), data)
  end
end

class BasicTopology < RedStorm::DSL::Topology
  spout SingleTupleSpout, :parallelism => 1

  bolt RedisPushBolt, :parallelism => 1 do
    source SingleTupleSpout, :global
  end

  configure do |environment|
    max_task_parallelism 1
    num_workers 1
    debug false
  end

  on_submit do |environment|
    case environment
    when :local
      sleep(10)
      cluster.shutdown
    end
  end

end
