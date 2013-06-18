# this example topology uses the Storm TestWordSpout and our own JRuby ExclamationBolt
# and a locally defined ExclamationBolt

java_import 'backtype.storm.testing.TestWordSpout'

require 'red_storm'

module RedStorm
  module Examples
    class ExclamationBolt < DSL::Bolt
      output_fields :word
      on_receive(:ack => true, :anchor => true) {|tuple| "!#{tuple[0]}!"} # tuple[:word] or tuple["word"] are also valid
    end

    class ExclamationTopology2 < DSL::Topology
      spout TestWordSpout, :parallelism => 2

      bolt ExclamationBolt, :parallelism => 2 do
        source TestWordSpout, :shuffle
      end

      bolt ExclamationBolt, :id => :ExclamationBolt2, :parallelism => 2 do
        source ExclamationBolt, :shuffle
      end

      configure do |env|
        debug true
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