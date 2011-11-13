module RedStorm

  class SimpleBolt

    # DSL class methods

    def self.output_fields(*fields)
      @fields = fields.map(&:to_s)
    end

    def self.on_receive(*args, &receive_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      method_name = args.first

      self.receive_options.merge!(options)
      @receive_block = block_given? ? receive_block : lambda {|tuple| self.send(method_name, tuple)}
    end

    def self.on_init(method_name = nil, &init_block)
      @init_block = block_given? ? init_block : lambda {self.send(method_name)}
    end

    def self.on_close(method_name = nil, &close_block)
      @close_block = block_given? ? close_block : lambda {self.send(method_name)}
    end

    # DSL instance methods

    def emit(*values)
      @collector.emit(Values.new(*values)) 
    end

    def ack(tuple)
      @collector.ack(tuple)
    end

    # Bolt proxy interface

    def execute(tuple)
      if (output = instance_exec(tuple, &self.class.receive_block)) && self.class.emit?
        values = [output].flatten
        self.class.anchor? ? @collector.emit(tuple, Values.new(*values)) : emit(*values)
        @collector.ack(tuple) if self.class.ack?
      end
    end

    def prepare(config, context, collector)
      @collector = collector
      @context = context
      @config = config
      instance_exec(&self.class.init_block)
    end

    def cleanup
      instance_exec(&self.class.close_block)
    end

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    private

    def self.fields
      @fields ||= []
    end

    def self.receive_block
      @receive_block ||= lambda {}
    end

    def self.init_block
      @init_block ||= lambda {}
    end

    def self.close_block
      @close_block ||= lambda {}
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
  end
end
