java_import 'backtype.storm.testing.TestWordSpout'

require 'red_storm'
require 'examples/simple/exclamation_bolt'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

module RedStorm
  module Examples
    class ExclamationTopology < SimpleTopology
      spout TestWordSpout, :parallelism => 2 do
        debug true
      end
      
      bolt ExclamationBolt, :parallelism => 2 do
        source TestWordSpout, :shuffle
      end
      
      bolt ExclamationBolt, :id => :ExclamationBolt2, :parallelism => 2 do
        source ExclamationBolt, :shuffle
        debug true
      end

      configure do |env|
        debug false
        max_task_parallelism 4
        if env == :cluster
          num_workers 4
          max_spout_pending(1000)
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