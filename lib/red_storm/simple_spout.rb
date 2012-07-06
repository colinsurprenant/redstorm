require 'red_storm/configurator'

module RedStorm

  class SimpleSpout
    attr_reader :config, :context, :collector

    # DSL class methods

    def self.configure(&configure_block)
      @configure_block = block_given? ? configure_block : lambda {}
    end

    def self.log
      @log ||= Logger.getLogger(self.name)
    end

    def self.output_fields(*fields)
      @fields = fields.map(&:to_s)
    end

    def self.on_send(*args, &on_send_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      method_name = args.first
      
      self.send_options.merge!(options)
      @on_send_block = block_given? ? on_send_block : lambda {self.send(method_name || :on_send)}
    end

    def self.on_init(method_name = nil, &on_init_block)
      @on_init_block = block_given? ? on_init_block : lambda {self.send(method_name || :on_init)}
    end

    def self.on_close(method_name = nil, &on_close_block)
      @on_close_block = block_given? ? on_close_block : lambda {self.send(method_name || :on_close)}
    end

    def self.on_activate(method_name = nil, &on_activate_block)
      @on_activate_block = block_given? ? on_activate_block : lambda {self.send(method_name || :on_activate)}
    end

    def self.on_deactivate(method_name = nil, &on_deactivate_block)
      @on_deactivate_block = block_given? ? on_deactivate_block : lambda {self.send(method_name || :on_deactivate)}
    end

    def self.on_ack(method_name = nil, &on_ack_block)
      @on_ack_block = block_given? ? on_ack_block : lambda {|msg_id| self.send(method_name || :on_ack, msg_id)}
    end

    def self.on_fail(method_name = nil, &on_fail_block)
      @on_fail_block = block_given? ? on_fail_block : lambda {|msg_id| self.send(method_name || :on_fail, msg_id)}
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
      output = instance_exec(&self.class.on_send_block)
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
          sleep(0.1)
        end
      end
    end

    def open(config, context, collector)
      @collector = collector
      @context = context
      @config = config
      instance_exec(&self.class.on_init_block)
    end

    def close
      instance_exec(&self.class.on_close_block)
    end

    def activate
      instance_exec(&self.class.on_activate_block)
    end

    def deactivate
      instance_exec(&self.class.on_deactivate_block)
    end

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    def ack(msg_id)
      instance_exec(msg_id, &self.class.on_ack_block)
    end

    def fail(msg_id)
      instance_exec(msg_id, &self.class.on_fail_block)
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

    def self.fields
      @fields ||= []
    end

    def self.configure_block
      @configure_block ||= lambda {}
    end

    def self.on_send_block
      @on_send_block ||= lambda {self.send(:on_send)}
    end

    def self.on_init_block
      @on_init_block ||= lambda {self.send(:on_init)}
    end

    def self.on_close_block
      @on_close_block ||= lambda {self.send(:on_close)}
    end

    def self.on_activate_block
      @on_activate_block ||= lambda {self.send(:on_activate)}
    end

    def self.on_deactivate_block
      @on_deactivate_block ||= lambda {self.send(:on_deactivate)}
    end

    def self.on_ack_block
      @on_ack_block ||= lambda {|msg_id| self.send(:on_ack, msg_id)}
    end

    def self.on_fail_block
      @on_fail_block ||= lambda {|msg_id| self.send(:on_fail, msg_id)}
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
  end
end
