module RedStorm

  class SimpleSpout


    # DSL class methods

    def self.output_fields(*fields)
      @fields = fields.map(&:to_s)
    end

    def self.on_send(*args, &send_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      method_name = args.first
      
      self.send_options.merge!(options)
      @send_block = block_given? ? send_block : lambda {self.send(method_name)}
    end

    def self.on_init(method_name = nil, &init_block)
      @init_block = block_given? ? init_block : lambda {self.send(method_name)}
    end

    def self.on_close(method_name = nil, &close_block)
      @close_block = block_given? ? close_block : lambda {self.send(method_name)}
    end

    def self.on_ack(method_name = nil, &ack_block)
      @ack_block = block_given? ? ack_block : lambda {|msg_id| self.send(method_name, msg_id)}
    end

    def self.on_fail(method_name = nil, &fail_block)
      @fail_block = block_given? ? fail_block : lambda {|msg_id| self.send(method_name, msg_id)}
    end

    def self.set(options = {})
      self.spout_options.merge!(options)
    end

    # DSL instance methods

    def emit(*values)
      @collector.emit(Values.new(*values)) 
    end

    # Spout proxy interface

    def next_tuple
      output = instance_exec(&self.class.send_block)
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
      instance_exec(&self.class.init_block)
    end

    def close
      instance_exec(&self.class.close_block)
    end

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    def is_distributed
      self.class.is_distributed?
    end

    def ack(msg_id)
      instance_exec(msg_id, &self.class.ack_block)
    end

    def fail(msg_id)
      instance_exec(msg_id, &self.class.fail_block)
    end

    private

    def self.fields
      @fields
    end

    def self.send_block
      @send_block ||= lambda {}
    end

    def self.init_block
      @init_block ||= lambda {}
    end

    def self.close_block
      @close_block ||= lambda {}
    end

    def self.ack_block
      @ack_block ||= lambda {}
    end

    def self.fail_block
      @fail_block ||= lambda {}
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
