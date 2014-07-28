require 'java'
require 'red_storm/configurator'
require 'red_storm/environment'
require 'pathname'

java_import 'backtype.storm.tuple.Fields'
java_import 'backtype.storm.tuple.Values'

module RedStorm
  module DSL

    class BoltError < StandardError; end

    class Bolt
      attr_reader :collector, :context, :config

      def self.java_proxy; "Java::RedstormStormJruby::JRubyBolt"; end

      # DSL class methods

      def self.log
        @log ||= Java::OrgApacheLog4j::Logger.getLogger(self.name)
      end

      def self.output_fields(*fields)
        @fields = fields.map(&:to_s)
      end

      def self.configure(&configure_block)
        @configure_block = block_given? ? configure_block : lambda {}
      end

      def self.on_receive(*args, &on_receive_block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        method_name = args.first

        self.receive_options.merge!(options)

        unless self.instance_methods.include?(:on_receive)
          # indirecting through a lambda defers the method lookup at invocation time
          # and the performance penalty is negligible
          body = block_given? ? on_receive_block : lambda{|tuple| self.send((method_name || :on_receive).to_sym, tuple)}
          define_method(:on_receive, body)
        end
      end

      def self.on_init(method_name = nil, &on_init_block)
        unless self.instance_methods.include?(:on_init)
          body = block_given? ? on_init_block : lambda {self.send((method_name || :on_init).to_sym)}
          define_method(:on_init, body)
        end
      end

      def self.on_close(method_name = nil, &on_close_block)
        unless self.instance_methods.include?(:on_close)
          body = block_given? ? on_close_block : lambda {self.send((method_name || :on_close).to_sym)}
          define_method(:on_close, body)
        end
      end

      # DSL instance methods

      def log
        self.class.log
      end

      def unanchored_emit(*values)
        @collector.emit_tuple(Values.new(*values))
      end

      def anchored_emit(tuple, *values)
        @collector.emit_anchor_tuple(tuple, Values.new(*values))
      end

      def ack(tuple)
        @collector.ack(tuple)
      end

      def fail(tuple)
        @collector.fail(tuple)
      end

      # Bolt proxy interface

      def execute(tuple)
        output = on_receive(tuple)
        if output && self.class.emit?
          values_list = !output.is_a?(Array) ? [[output]] : !output.first.is_a?(Array) ? [output] : output
          values_list.each{|values| self.class.anchor? ? anchored_emit(tuple, *values) : unanchored_emit(*values)}
          @collector.ack(tuple) if self.class.ack?
        end
      end

      def prepare(config, context, collector)
        @collector = collector
        @context = context
        @config = config

        on_init
      end

      def cleanup
        on_close
      end

      def declare_output_fields(declarer)
        declarer.declare(Fields.new(self.class.fields))
      end

      def get_component_configuration
        configurator = Configurator.new
        configurator.instance_exec(&self.class.configure_block)
        configurator.config
      end

      private

      # default noop optional dsl callbacks
      def on_init; end
      def on_close; end

      def self.fields
        @fields ||= []
      end

      def self.configure_block
        @configure_block ||= lambda {}
      end

      def self.receive_options
        @receive_options ||= {:emit => true, :ack => false, :anchor => false}
      end

      def self.emit?
        !!self.receive_options[:emit]
      end

      def self.ack?
        !!self.receive_options[:ack]
      end

      def self.anchor?
        !!self.receive_options[:anchor]
      end

      # below non-dry see Spout class
      def self.inherited(subclass)
        path = (caller.first.to_s =~ /^(.+):\d+.*$/) ? $1 : raise(BoltError, "unable to extract base topology class path from #{caller.first.inspect}")
        subclass.base_class_path = Pathname.new(path).relative_path_from(Pathname.new(RedStorm::BASE_PATH)).to_s
      end

      def self.base_class_path=(path)
        @base_class_path = path
      end

      def self.base_class_path
        @base_class_path
      end

    end
  end

  # for backward compatibility
  SimpleBolt = DSL::Bolt

end
