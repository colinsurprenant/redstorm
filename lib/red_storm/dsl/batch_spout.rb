module RedStorm
  module DSL

    class BatchSpout < Spout

      def self.java_proxy; "Java::RedstormStormJruby::JRubyBatchSpout"; end

      def get_output_fields
        Fields.new(self.class.fields)
      end

      def self.on_emit_batch(*args, &on_emit_batch_block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        method_name = args.first

        self.on_emit_batch_options.merge!(options)

        # indirecting through a lambda defers the method lookup at invocation time
        # and the performance penalty is negligible
        body = block_given? ? on_emit_batch_block : lambda{|batch_id, collector| self.send((method_name || :on_emit_batch).to_sym)}
        define_method(:on_emit_batch, body)
      end

      # Spout proxy interface

      #
      # note that in batch spout, ack is for the batch id and not the message id as in the base spout.
      # TODO maybe rename msg_id to just id in the base spout
      #

      def emit_batch(batch_id, collector)
        # TODO this is a TridentCollector, emit should just work by setting @collector
        # report_error need to be hooked?
        @collector = collector
        on_emit_batch(batch_id, collector)
      end

      def open(config, context)
        @context = context
        @config = config

        on_init
      end

      private

      def self.on_emit_batch_options
        @on_emit_batch_options ||= {}
      end

    end
  end
end
