module RedStorm
  module Examples
    class SplitSentenceBolt
      def prepare(conf, context, collector)
        @collector = collector
      end

      def execute(tuple)
        tuple.getString(0).split(" ").each {|w| @collector.emit(Values.new(w)) }
      end

      def get_component_configuration
      end

      def declare_output_fields(declarer)
        declarer.declare(Fields.new("word"))
      end
    end
  end
end
