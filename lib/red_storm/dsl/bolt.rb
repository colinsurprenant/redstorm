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
        @fields ||= []
        fields.each do |field|
          if field.kind_of? Hash
            @fields << Hash[
              field.map { |k, v| [k.to_s, v.kind_of?(Array) ? v.map(&:to_s) : v.to_s] }
            ]
          else
            @fields << field.to_s
          end
        end
      end

      def self.configure(&configure_block)
        @configure_block = block_given? ? configure_block : lambda {}
      end

      def self.on_receive(*args, &on_receive_block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        method_name = args.first

        self.receive_options.merge!(options)

        # indirecting through a lambda defers the method lookup at invocation time
        # and the performance penalty is negligible
        body = block_given? ? on_receive_block : lambda{|tuple| self.send((method_name || :on_receive).to_sym, tuple)}
        define_method(:on_receive, body)
      end

      def self.on_init(method_name = nil, &on_init_block)
        body = block_given? ? on_init_block : lambda {self.send((method_name || :on_init).to_sym)}
        define_method(:on_init, body)
      end

      def self.on_close(method_name = nil, &on_close_block)
        body = block_given? ? on_close_block : lambda {self.send((method_name || :on_close).to_sym)}
        define_method(:on_close, body)
      end

      # DSL instance methods

      def log
        self.class.log
      end

      def stream
        self.class.stream
      end

      def unanchored_emit(*values)
        @collector.emit_tuple(Values.new(*values))
      end

      def unanchored_stream_emit(stream, *values)
        @collector.emit_tuple_stream(stream, Values.new(*values))
      end

      def anchored_emit(tuple, *values)
        @collector.emit_anchor_tuple(tuple, Values.new(*values))
      end

      def anchored_stream_emit(stream, tuple, *values)
        @collector.emit_anchor_tuple_stream(stream, tuple, Values.new(*values))
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
          values_list.each do |values|
            if self.class.anchor?
              if self.class.stream?
                anchored_stream_emit(self.stream, tuple, *values)
              else
                anchored_emit(tuple, *values)
              end
            else
              if self.class.stream?
                unanchored_stream_emit(self.stream, *values)
              else
                unanchored_emit(*values)
              end
            end
          end
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
        default_fields = []
        self.class.fields.each do |field|
          if field.kind_of? Hash
            field.each do |stream, fields|
              declarer.declareStream(stream, Fields.new(fields))
            end
          else
            default_fields << field
          end
        end

        declarer.declare(Fields.new(default_fields.flatten)) unless default_fields.empty?
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

      def self.stream?
        self.receive_options[:stream] && !self.receive_options[:stream].empty?
      end

      def self.stream
        self.receive_options[:stream]
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
