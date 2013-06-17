require 'red_storm'
require 'thread'
require 'redis'

class ReliableSpout < RedStorm::DSL::Spout
  output_fields :string

  on_init do
    @redis = Redis.new(:host => "localhost", :port => 6379)
    @ids = [1, 2]

    @q = Queue.new
    @ids.each{|id| @q << id}
  end

  on_fail do |id|
    log.info("***** FAIL #{id}")
  end

  on_ack do |id|
    @ids.delete(id)
    log.info("***** ACK #{id}")
    if @ids.empty?
      log.info("*** SUCCESS")
      @redis.lpush(File.basename(__FILE__), "SUCCESS")
    end
  end

  on_send :reliable => true do
    # avoid putting the thread to sleep endlessly on @q.pop which will prevent local cluster.shutdown
    sleep(1)
    unless @q.empty?
      id = @q.pop
      [id, "DATA#{id}"] # reliable & autoemit, first element must be message_id
    end
  end
end

class AckBolt < RedStorm::DSL::Bolt
  on_receive :emit => false do |tuple|
    ack(tuple)
  end
end

class ImplicitPassthruBolt < RedStorm::DSL::Bolt
  output_fields :string

  on_receive :emit => true, :ack => true, :anchor => true do |tuple|
    tuple[0]
  end
end

class ExplicitPassthruBolt < RedStorm::DSL::Bolt
  output_fields :string

  on_receive :emit => false do |tuple|
    anchored_emit(tuple, tuple[0])
    ack(tuple)
  end
end

class ReliableTopology < RedStorm::DSL::Topology
  spout ReliableSpout, :parallelism => 1

  bolt ImplicitPassthruBolt, :parallelism => 1 do
    source ReliableSpout, :shuffle
  end

  bolt ExplicitPassthruBolt, :parallelism => 1 do
    source ImplicitPassthruBolt, :shuffle
  end

  bolt AckBolt, :parallelism => 1 do
    source ExplicitPassthruBolt, :shuffle
  end

  configure do |environment|
    debug true
    message_timeout_secs 10
    num_ackers 2
  end

  on_submit do |environment|
    case environment
    when :local
      sleep(10)
      cluster.shutdown
    end
  end

end
