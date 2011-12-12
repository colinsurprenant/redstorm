require 'examples/simple/random_sentence_spout'
require 'examples/simple/split_sentence_bolt'
require 'examples/simple/word_count_bolt'

module RedStorm
  module Examples
    class WordCountTopology < SimpleTopology
      spout RandomSentenceSpout, :parallelism => 5
      
      bolt SplitSentenceBolt, :parallelism => 8 do
        source RandomSentenceSpout, :shuffle
      end
      
      bolt WordCountBolt, :parallelism => 12 do
        source SplitSentenceBolt, :fields => ["word"]
      end

      configure :word_count do |env|
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