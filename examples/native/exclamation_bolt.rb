module RedStorm
  module Examples
    class ExclamationBolt
      def prepare(conf, context, collector)
        @collector = collector
      end

      def execute(tuple)
        @collector.emit(tuple, Values.new(tuple.getString(0) + "!!!"))
        @collector.ack(tuple)
      end

      def get_component_configuration
      end

      def declare_output_fields(declarer)
        declarer.declare(Fields.new("word"))
      end
    end
  end
end
