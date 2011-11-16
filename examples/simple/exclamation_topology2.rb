java_import 'backtype.storm.testing.TestWordSpout'
require 'red_storm'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt
# and a locally defined ExclamationBolt

class ExclamationBolt < RedStorm::SimpleBolt
  output_fields :word
  on_receive(:ack => true, :anchor => true) {|tuple| "!#{tuple.getString(0)}!"}
end

class ExclamationTopology2 < RedStorm::SimpleTopology
  spout TestWordSpout, :parallelism => 10
  
  bolt ExclamationBolt, :parallelism => 3 do
    source TestWordSpout, :shuffle
  end
  
  bolt ExclamationBolt, :id => :ignore, :parallelism => 2 do
    source ExclamationBolt, :shuffle
  end

  configure do |env|
    case env
    when :local
      debug true
      max_task_parallelism 3
    when :cluster
      debug true
      num_workers 20
      max_spout_pending(1000);
    end
  end

  on_submit do |env|
    if env == :local
      sleep(5)
      cluster.shutdown
    end
  end
end