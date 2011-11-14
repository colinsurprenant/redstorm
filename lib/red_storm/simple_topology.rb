module RedStorm

  class SimpleTopology
    attr_reader :cluster # LocalCluster reference usable in on_submit block for example

    class BoltDefinition
      attr_reader :bolt_class, :id, :parallelism

      def initialize(bolt_class, id, parallelism)
        @bolt_class = bolt_class
        @id = id
        @parallelism = parallelism
        @sources = []
      end

      def source(source_id, grouping)
        @sources << [source_id, grouping.is_a?(Hash) ? grouping : {grouping => nil}]
      end

      def define_grouping(storm_bolt)
        @sources.each do |source_id, grouping|
          grouper, params = grouping.first

          case grouper
          when :shuffle
            storm_bolt.shuffleGrouping(source_id)
          when :fields
            storm_bolt.fieldsGrouping(source_id, Fields.new(*params))
          else
            raise("unknown grouper=#{grouper.inspect}")
          end
        end
      end
    end

    class SpoutDefinition
      attr_reader :spout_class, :id, :parallelism

      def initialize(spout_class, id, parallelism)
        @spout_class = spout_class
        @id = id
        @parallelism = parallelism
      end
    end

    class Configurator
      attr_reader :config

      def initialize
        @config = Config.new
      end

      def method_missing(sym, *args)
        config_method = "set#{self.class.camel_case(sym)}"
        @config.send(config_method, *args)
      end

      private

      def self.camel_case(s)
        s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
    end


    def self.spout(spout_class, options = {})
      spout_options = {:id => self.underscore(spout_class), :parallelism => 1}.merge(options)
      spout = SpoutDefinition.new(spout_class, spout_options[:id], spout_options[:parallelism])
      self.spouts << spout
    end

    def self.bolt(bolt_class, options = {}, &bolt_block)
      bolt_options = {:id => self.underscore(bolt_class), :parallelism => 1}.merge(options)
      bolt = BoltDefinition.new(bolt_class, bolt_options[:id], bolt_options[:parallelism])
      bolt.instance_exec(&bolt_block)
      self.bolts << bolt
    end

    def self.configure(name = nil, &configure_block)
      @topology_name = name if name
      @configure_block = configure_block if block_given?
    end

    def self.on_submit(method_name = nil, &submit_block)
      @submit_block = block_given? ? submit_block : lambda {|env| self.send(method_name, env)}
    end

    # topology proxy interface

    def start(base_class_path, env)
      builder = TopologyBuilder.new
      self.class.spouts.each do |spout|
         builder.setSpout(spout.id, JRubySpout.new(base_class_path, spout.spout_class.name), spout.parallelism)
      end
      self.class.bolts.each do |bolt|
        storm_bolt = builder.setBolt(bolt.id, JRubyBolt.new(base_class_path, bolt.bolt_class.name), bolt.parallelism)
        bolt.define_grouping(storm_bolt)
      end

      configurator = Configurator.new
      configurator.instance_exec(env, &self.class.configure_block)
 
      case env
      when :local
        @cluster = LocalCluster.new
        @cluster.submitTopology(self.class.topology_name, configurator.config, builder.createTopology)
      when :cluster
        StormSubmitter.submitTopology(self.class.topology_name, configurator.config, builder.createTopology);
      else
        raise("unsupported env=#{env.inspect}, expecting :local or :cluster")
      end

      instance_exec(env, &self.class.submit_block)
    end

    private

    def self.spouts
      @spouts ||= []
    end

    def self.bolts
      @bolts ||= []
    end

    def self.topology_name
      @topology_name ||= self.underscore(self.name)
    end

    def self.configure_block
      @configure_block ||= lambda{|env|}
    end

    def self.submit_block
      @submit_block ||= lambda{|env|}
    end

    def self.underscore(camel_case)
      camel_case.to_s.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase!
    end
  end
end