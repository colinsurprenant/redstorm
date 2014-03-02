module RedStorm
  module DSL

    class BatchBolt < Bolt
      attr_reader :id

      def self.java_proxy; "Java::RedstormStormJruby::JRubyBatchBolt"; end

      def self.on_finish_batch(method_name = nil, &on_finish_batch_block)
        body = block_given? ? on_finish_batch_block : lambda {self.send((method_name || :on_finish_batch).to_sym)}
        define_method(:on_finish_batch, body)
      end

      def prepare(config, context, collector, id)
        @collector = collector
        @context = context
        @config = config
        @id = id

        on_init
      end

      def finish_batch
        on_finish_batch
      end

      private

      # default noop optional dsl callbacks
      def on_finish_batch; end

    end
  end
end