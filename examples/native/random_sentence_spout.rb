module RedStorm
  module Examples
    class RandomSentenceSpout
      attr_reader :is_distributed

      def initialize
        @is_distributed = true
        @sentences = [
          "the cow jumped over the moon",
          "an apple a day keeps the doctor away",
          "four score and seven years ago",
          "snow white and the seven dwarfs",
          "i am at two with nature"
        ]
      end 

      def open(conf, context, collector)
        @collector = collector
      end
      
      def next_tuple
        @collector.emit(Values.new(@sentences[rand(@sentences.length)]))
      end

      def declare_output_fields(declarer)
        declarer.declare(Fields.new("word"))
      end
    end
  end
end