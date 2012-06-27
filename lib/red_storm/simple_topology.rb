require 'java'
require 'red_storm/configuration'
require 'red_storm/configurator'

module RedStorm

  class TopologyDefinitionError < StandardError; end

  class SimpleTopology
    attr_reader :cluster # LocalCluster reference usable in on_submit block, for example

    DEFAULT_SPOUT_PARALLELISM = 1
    DEFAULT_BOLT_PARALLELISM = 1

    class ComponentDefinition < Configurator
      attr_reader :clazz, :parallelism
      attr_accessor :id # ids are forced to string

      def initialize(component_class, id, parallelism)
        super()
        @clazz = component_class
        @id = id.to_s
        @parallelism = parallelism
      end

      def is_java?
        @clazz.name.split('::').first.downcase == 'java'
      end
    end

    class SpoutDefinition < ComponentDefinition
      def new_instance(base_class_path)
        is_java? ? @clazz.new : JRubySpout.new(base_class_path, @clazz.name)
      end
    end
          
    class BoltDefinition < ComponentDefinition
      attr_accessor :sources

      def initialize(*args)
        super
        @sources = []
      end

      def source(source_id, grouping)
        @sources << [source_id.is_a?(Class) ? SimpleTopology.underscore(source_id) : source_id.to_s, grouping.is_a?(Hash) ? grouping : {grouping => nil}]
      end

      def define_grouping(declarer)
        @sources.each do |source_id, grouping|
          grouper, params = grouping.first
            # declarer.fieldsGrouping(source_id, Fields.new())
          case grouper
          when :fields
            declarer.fieldsGrouping(source_id, Fields.new(*([params].flatten.map(&:to_s))))
          when :global
            declarer.globalGrouping(source_id)
          when :shuffle
            declarer.shuffleGrouping(source_id)
          when :local_or_shuffle
            declarer.localOrShuffleGrouping(source_id)
          when :none
            declarer.noneGrouping(source_id)
          when :all
            declarer.allGrouping(source_id)
          when :direct
            declarer.directGrouping(source_id)
          else
            raise("unknown grouper=#{grouper.inspect}")
          end
        end
      end

      def new_instance(base_class_path)
        is_java? ? @clazz.new : JRubyBolt.new(base_class_path, @clazz.name)
      end
    end

    def self.log
      @log ||= org.apache.log4j.Logger.getLogger(self.name)
    end

    def self.spout(spout_class, options = {}, &spout_block)
      spout_options = {:id => self.underscore(spout_class), :parallelism => DEFAULT_SPOUT_PARALLELISM}.merge(options)
      spout = SpoutDefinition.new(spout_class, spout_options[:id], spout_options[:parallelism])
      spout.instance_exec(&spout_block) if block_given?
      self.components << spout
    end

    def self.bolt(bolt_class, options = {}, &bolt_block)
      bolt_options = {:id => self.underscore(bolt_class), :parallelism => DEFAULT_BOLT_PARALLELISM}.merge(options)
      bolt = BoltDefinition.new(bolt_class, bolt_options[:id], bolt_options[:parallelism])
      raise(TopologyDefinitionError, "#{bolt.clazz.name}, #{bolt.id}, bolt definition body required") unless block_given?
      bolt.instance_exec(&bolt_block)
      self.components << bolt
    end

    def self.configure(name = nil, &configure_block)
      Configuration.topology_class = self
      @topology_name = name if name
      @configure_block = configure_block if block_given?
    end

    def self.on_submit(method_name = nil, &submit_block)
      @submit_block = block_given? ? submit_block : lambda {|env| self.send(method_name, env)}
    end

    # topology proxy interface

    def start(base_class_path, env)
      self.class.resolve_ids!(self.class.components)

      builder = TopologyBuilder.new
      self.class.spouts.each do |spout|
        declarer = builder.setSpout(spout.id, spout.new_instance(base_class_path), spout.parallelism.to_java)
        declarer.addConfigurations(spout.config)
      end
      self.class.bolts.each do |bolt|
        declarer = builder.setBolt(bolt.id, bolt.new_instance(base_class_path), bolt.parallelism.to_java)
        declarer.addConfigurations(bolt.config)
        bolt.define_grouping(declarer)
      end

      configurator = Configurator.new
      configurator.instance_exec(env, &self.class.configure_block)
 
      submitter = (env == :local) ? @cluster = LocalCluster.new : StormSubmitter
      submitter.submitTopology(self.class.topology_name, configurator.config, builder.createTopology)
      instance_exec(env, &self.class.submit_block)
    end

    private

    def self.resolve_ids!(components)
      # verify duplicate implicit ids
      ids = components.map(&:id)
      components.reverse.each do |component|
        raise("duplicate id in #{component.clazz.name} on id=#{component.id}") if ids.select{|id| id == component.id}.size > 1
        # verify source_id references
        if component.respond_to?(:sources)
          component.sources.each{|source_id, grouping| raise("cannot resolve #{component.clazz.name} source id=#{source_id}") unless ids.include?(source_id)}
        end
      end
    end

    def self.spouts
      self.components.select{|c| c.is_a?(SpoutDefinition)}
    end

    def self.bolts
      self.components.select{|c| c.is_a?(BoltDefinition)}
    end

    def self.components
      @components ||= []
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
