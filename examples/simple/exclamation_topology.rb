java_import 'backtype.storm.testing.TestWordSpout'

require 'examples/simple/exclamation_bolt'

# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt

module RedStorm
  module Examples
    class ExclamationTopology < RedStorm::SimpleTopology
      spout TestWordSpout, :parallelism => 5 do
        debug true
      end
      
      bolt ExclamationBolt, :parallelism => 2 do
        source TestWordSpout, :shuffle
        # max_task_parallelism 1
      end
      
      bolt ExclamationBolt, :id => :ExclamationBolt2, :parallelism => 2 do
        source ExclamationBolt, :shuffle
        # max_task_parallelism 1
        debug true
      end

      configure do |env|
        debug false
        set "topology.worker.childopts", "-Djruby.compat.version=RUBY1_9"
        case env
        when :local
          max_task_parallelism 40
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