require 'java'
require 'red_storm/configurator'
require 'red_storm/environment'
require 'red_storm/dsl/output_fields'
require 'pathname'

module RedStorm
  module DSL

    class SpoutError < StandardError; end

    class Spout
      attr_reader :config, :context, :collector

      include OutputFields

      def self.java_proxy; "Java::RedstormStormJruby::JRubySpout"; end

      # DSL class methods

      def self.configure(&configure_block)
        @configure_block = block_given? ? configure_block : lambda {}
      end

      def self.log
        @log ||= Java::OrgApacheLog4j::Logger.getLogger(self.name)
      end

      def self.on_send(*args, &on_send_block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        method_name = args.first

        self.send_options.merge!(options)

        # indirecting through a lambda defers the method lookup at invocation time
        # and the performance penalty is negligible
        body = block_given? ? on_send_block : lambda{self.send((method_name || :on_send).to_sym)}
        define_method(:on_send, body)
      end

      def self.on_init(method_name = nil, &on_init_block)
        body = block_given? ? on_init_block : lambda {self.send((method_name || :on_init).to_sym)}
        define_method(:on_init, body)
      end

      def self.on_close(method_name = nil, &on_close_block)
        body = block_given? ? on_close_block : lambda {self.send((method_name || :on_close).to_sym)}
        define_method(:on_close, body)
      end

      def self.on_activate(method_name = nil, &on_activate_block)
        # @on_activate_block = block_given? ? on_activate_block : lambda {self.send(method_name || :on_activate)}
        body = block_given? ? on_activate_block : lambda {self.send((method_name || :on_activate).to_sym)}
        define_method(:on_activate, body)
      end

      def self.on_deactivate(method_name = nil, &on_deactivate_block)
        # @on_deactivate_block = block_given? ? on_deactivate_block : lambda {self.send(method_name || :on_deactivate)}
        body = block_given? ? on_deactivate_block : lambda {self.send((method_name || :on_deactivate).to_sym)}
        define_method(:on_deactivate, body)
      end

      def self.on_ack(method_name = nil, &on_ack_block)
        body = block_given? ? on_ack_block : lambda {|msg_id| self.send((method_name || :on_ack).to_sym, msg_id)}
        define_method(:on_ack, body)
      end

      def self.on_fail(method_name = nil, &on_fail_block)
        body = block_given? ? on_fail_block : lambda {|msg_id| self.send((method_name || :on_fail).to_sym, msg_id)}
        define_method(:on_fail, body)
      end

      # DSL instance methods

      def reliable_emit(message_id, *values)
        @collector.emit(Values.new(*values), message_id)
      end

      def unreliable_emit(*values)
        @collector.emit(Values.new(*values))
      end
      alias_method :emit, :unreliable_emit

      def log
        self.class.log
      end

      # Spout proxy interface

      def next_tuple
        output = on_send

        if self.class.emit?
          if output
            values = [output].flatten
            if self.class.reliable?
              message_id = values.shift
              reliable_emit(message_id, *values)
            else
              unreliable_emit(*values)
            end
          else
            sleep(0.1)  # see https://twitter.com/colinsurprenant/status/406445541904494592
          end
        end
      end

      def open(config, context, collector)
        @collector = collector
        @context = context
        @config = config

        on_init
      end

      def close
        on_close
      end

      def activate
        on_activate
      end

      def deactivate
        on_deactivate
      end

      def ack(msg_id)
        on_ack(msg_id)
      end

      def fail(msg_id)
        on_fail(msg_id)
      end

      def get_component_configuration
        configurator = Configurator.new
        configurator.instance_exec(&self.class.configure_block)
        configurator.config
      end

      private

      # default optional noop dsl methods/callbacks
      def on_init; end
      def on_close; end
      def on_activate; end
      def on_deactivate; end
      def on_ack(msg_id); end
      def on_fail(msg_id); end

      def self.configure_block
        @configure_block ||= lambda {}
      end

      def self.send_options
        @send_options ||= {:emit => true, :reliable => false}
      end

      def self.emit?
        !!self.send_options[:emit]
      end

      def self.reliable?
        !!self.send_options[:reliable]
      end

      # below non-dry see Bolt class
      def self.inherited(subclass)
        path = (caller.first.to_s =~ /^(.+):\d+.*$/) ? $1 : raise(SpoutError, "unable to extract base topology class path from #{caller.first.inspect}")
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
  SimpleSpout = DSL::Spout

end
