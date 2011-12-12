java_import 'backtype.storm.testing.TestWordSpout'

require 'examples/simple/exclamation_bolt'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

module RedStorm
  module Examples
    class ExclamationTopology < RedStorm::SimpleTopology
      spout TestWordSpout, :parallelism => 10
      
      bolt ExclamationBolt, :parallelism => 3 do
        source TestWordSpout, :shuffle
      end
      
      bolt ExclamationBolt, :id => :ExclamationBolt2, :parallelism => 2 do
        source ExclamationBolt, :shuffle
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

      on_submit do |env|
        if env == :local
          sleep(5)
          cluster.shutdown
        end
      end
    end
  end
end