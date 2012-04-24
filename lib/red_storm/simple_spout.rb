module RedStorm

  class SimpleSpout
    attr_reader :config, :context, :collector

    # DSL class methods

    def self.set(options = {})
      self.spout_options.merge!(options)
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

    def self.on_ack(method_name = nil, &on_ack_block)
      @on_ack_block = block_given? ? on_ack_block : lambda {|msg_id| self.send(method_name || :on_ack, msg_id)}
    end

    def self.on_fail(method_name = nil, &on_fail_block)
      @on_fail_block = block_given? ? on_fail_block : lambda {|msg_id| self.send(method_name || :on_fail, msg_id)}
    end

    # DSL instance methods

    def emit(*values)
      @collector.emit(Values.new(*values)) 
    end

    def log
      self.class.log
    end

    # Spout proxy interface

    def next_tuple
      output = instance_exec(&self.class.on_send_block)
      if self.class.emit?
        if output
          values = [output].flatten
          @collector.emit(Values.new(*values))
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

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    def is_distributed
      self.class.is_distributed?
    end

    def ack(msg_id)
      instance_exec(msg_id, &self.class.on_ack_block)
    end

    def fail(msg_id)
      instance_exec(msg_id, &self.class.on_fail_block)
    end

    private

    # default optional noop dsl methods/callbacks
    def on_init; end
    def on_close; end
    def on_ack(msg_id); end
    def on_fail(msg_id); end

    def self.fields
      @fields ||= []
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

    def self.on_ack_block
      @on_ack_block ||= lambda {|msg_id| self.send(:on_ack, msg_id)}
    end

    def self.on_fail_block
      @on_fail_block ||= lambda {|msg_id| self.send(:on_fail, msg_id)}
    end

    def self.send_options
      @send_options ||= {:emit => true}
    end

    def self.spout_options
      @spout_options ||= {:is_distributed => false}
    end

    def self.is_distributed?
      !!self.spout_options[:is_distributed]
    end

    def self.emit?
      !!self.send_options[:emit]
    end
  end
end
