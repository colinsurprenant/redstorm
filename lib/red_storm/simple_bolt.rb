module RedStorm

  class SimpleBolt
    attr_reader :collector, :context, :config

    # DSL class methods

    def self.log
      @log ||= Logger.getLogger(self.name)
    end

    def self.output_fields(*fields)
      @fields = fields.map(&:to_s)
    end

    def self.on_receive(*args, &on_receive_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      method_name = args.first

      self.receive_options.merge!(options)
      @on_receive_block = block_given? ? on_receive_block : lambda {|tuple| self.send(method_name || :on_receive, tuple)}
    end

    def self.on_init(method_name = nil, &on_init_block)
      @on_init_block = block_given? ? on_init_block : lambda {self.send(method_name || :on_init)}
    end

    def self.on_close(method_name = nil, &close_block)
      @close_block = block_given? ? close_block : lambda {self.send(method_name || :on_close)}
    end

    # DSL instance methods

    def log
      self.class.log
    end

    def unanchored_emit(*values)
      @collector.emit(Values.new(*values)) 
    end

    def anchored_emit(tuple, *values)
      @collector.emit(tuple, Values.new(*values)) 
    end

    def ack(tuple)
      @collector.ack(tuple)
    end

    # Bolt proxy interface

    def execute(tuple)
      if (output = instance_exec(tuple, &self.class.on_receive_block)) && self.class.emit?
        values_list = !output.is_a?(Array) ? [[output]] : !output.first.is_a?(Array) ? [output] : output
        values_list.each{|values| self.class.anchor? ? anchored_emit(tuple, *values) : unanchored_emit(*values)}
        @collector.ack(tuple) if self.class.ack?
      end
    end

    def prepare(config, context, collector)
      @collector = collector
      @context = context
      @config = config
      instance_exec(&self.class.on_init_block)
    end

    def cleanup
      instance_exec(&self.class.close_block)
    end

    def declare_output_fields(declarer)
      declarer.declare(Fields.new(self.class.fields))
    end

    private

    # default noop optional dsl callbacks
    def on_init; end
    def on_close; end

    def self.fields
      @fields ||= []
    end

    def self.on_receive_block
      @on_receive_block ||= lambda {|tuple| self.send(:on_receive, tuple)}
    end

    def self.on_init_block
      @on_init_block ||= lambda {self.send(:on_init)}
    end

    def self.close_block
      @close_block ||= lambda {self.send(:on_close)}
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
