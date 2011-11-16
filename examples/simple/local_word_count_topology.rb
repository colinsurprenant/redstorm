require 'red_storm'
require 'examples/simple/random_sentence_spout'
require 'examples/simple/split_sentence_bolt'
require 'examples/simple/word_count_bolt'

class LocalWordCountTopology < RedStorm::SimpleTopology
  spout RandomSentenceSpout, :parallelism => 5
  
  bolt SplitSentenceBolt, :parallelism => 8 do
    source RandomSentenceSpout, :shuffle
  end
  
  bolt WordCountBolt, :parallelism => 12 do
    source SplitSentenceBolt, :fields => ["word"]
  end

  configure :word_count do |env|
    debug true
    max_task_parallelism 3
  end

  on_submit do |env|
    if env == :local
      sleep(5)
      cluster.shutdown
    end
  end
end