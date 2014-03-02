module RedStorm
  module DSL

    class BatchCommitterBolt < BatchBolt

      def self.java_proxy; "Java::RedstormStormJruby::JRubyBatchCommitterBolt"; end
    end
  end
end