require 'java'
require 'red_storm/configuration'
require 'red_storm/configurator'

java_import 'backtype.storm.topology.TopologyBuilder'
java_import 'backtype.storm.generated.SubmitOptions'
java_import 'backtype.storm.utils.Utils'

module RedStorm
  module DSL

    class TopologyDefinitionError < StandardError; end

    class Topology
      attr_reader :cluster # LocalCluster reference usable in on_submit block, for example

      DEFAULT_SPOUT_PARALLELISM = 1
      DEFAULT_BOLT_PARALLELISM = 1

      class ComponentDefinition < Configurator
        attr_reader :clazz, :constructor_args, :parallelism
        attr_accessor :id # ids are forced to string

        def initialize(component_class, constructor_args, id, parallelism)
          super()
          @clazz = component_class
          @constructor_args = constructor_args
          @id = id.to_s
          @parallelism = parallelism
          @output_fields = Hash.new([])

          initialize_output_fields
        end

        def output_fields(*fields)
          default_fields = []
          fields.each do |field|
            case field
            when Hash
              field.each { |k, v| @output_fields[k.to_s] = v.kind_of?(Array) ? v.map(&:to_s) : [v.to_s] }
            else
              default_fields |= field.kind_of?(Array) ? field.map(&:to_s) : [field.to_s]
            end
          end
          @output_fields[Utils::DEFAULT_STREAM_ID] = default_fields unless default_fields.empty?

          @output_fields
        end

        def is_java?
          @clazz.name.split('::').first.downcase == 'java'
        end

        private

        def initialize_output_fields
          if @clazz.ancestors.include?(RedStorm::DSL::OutputFields)
            @output_fields = @clazz.fields.clone
          end
        end

        def java_safe_fields
          java_hash = java.util.HashMap.new()
          @output_fields.each do |k, v|
            java_hash.put(k, v.to_java('java.lang.String')) unless v.empty?
          end
          java_hash
        end
      end

      class SpoutDefinition < ComponentDefinition

        # WARNING non-dry see BoltDefinition#new_instance
        def new_instance
          if @clazz.name == "Java::RedstormStormJruby::JRubyShellSpout"
            @clazz.new(constructor_args, @output_fields)
          elsif is_java?
            @clazz.new(*constructor_args)
          else
            Object.module_eval(@clazz.java_proxy).new(@clazz.base_class_path, @clazz.name, java_safe_fields)
          end
        end
      end

      class BoltDefinition < ComponentDefinition
        attr_accessor :sources, :command

        def initialize(*args)
          super
          @sources = []
        end

        def source(source_id, grouping, stream = Utils::DEFAULT_STREAM_ID)
          @sources << [
            source_id.is_a?(Class) ? Topology.underscore(source_id) : source_id.to_s,
            grouping.is_a?(Hash) ? grouping : {grouping => nil},
            stream.to_s
          ]
        end

        def define_grouping(declarer)
          @sources.each do |source_id, grouping, stream|
            grouper, params = grouping.first
              # declarer.fieldsGrouping(source_id, Fields.new())
            case grouper
            when :fields
              declarer.fieldsGrouping(source_id, stream, Fields.new(*([params].flatten.map(&:to_s))))
            when :global
              declarer.globalGrouping(source_id, stream)
            when :shuffle
              declarer.shuffleGrouping(source_id, stream)
            when :local_or_shuffle
              declarer.localOrShuffleGrouping(source_id, stream)
            when :none
              declarer.noneGrouping(source_id, stream)
            when :all
              declarer.allGrouping(source_id, stream)
            when :direct
              declarer.directGrouping(source_id, stream)
            else
              raise("unknown grouper=#{grouper.inspect}")
            end
          end
        end

        def new_instance
          # WARNING non-dry see BoltDefinition#new_instance
          if @clazz.name == "Java::RedstormStormJruby::JRubyShellBolt"
            @clazz.new(constructor_args, @output_fields)
          elsif is_java?
            @clazz.new(*constructor_args)
          else
            Object.module_eval(@clazz.java_proxy).new(@clazz.base_class_path, @clazz.name, java_safe_fields)
          end
        end
      end

      def self.log
        @log ||= Java::OrgApacheLog4j::Logger.getLogger(self.name)
      end

      # def self.spout(spout_class, contructor_args = [], options = {}, &spout_block)
      def self.spout(spout_class, *args, &spout_block)
        set_topology_class!
        options = args.last.is_a?(Hash) ? args.pop : {}
        contructor_args = !args.empty? ? args.pop : []
        spout_options = {:id => self.underscore(spout_class), :parallelism => DEFAULT_SPOUT_PARALLELISM}.merge(options)

        spout = SpoutDefinition.new(spout_class, contructor_args, spout_options[:id], spout_options[:parallelism])
        spout.instance_exec(&spout_block) if block_given?
        self.components << spout
      end

      # def self.bolt(bolt_class, contructor_args = [], options = {}, &bolt_block)
      def self.bolt(bolt_class, *args, &bolt_block)
        set_topology_class!
        options = args.last.is_a?(Hash) ? args.pop : {}
        contructor_args = !args.empty? ? args.pop : []
        bolt_options = {:id => self.underscore(bolt_class), :parallelism => DEFAULT_BOLT_PARALLELISM}.merge(options)

        bolt = BoltDefinition.new(bolt_class, contructor_args, bolt_options[:id], bolt_options[:parallelism])
        raise(TopologyDefinitionError, "#{bolt.clazz.name}, #{bolt.id}, bolt definition body required") unless block_given?
        bolt.instance_exec(&bolt_block)
        self.components << bolt
      end

      def self.configure(name = nil, &configure_block)
        set_topology_class!
        @topology_name = name.to_s if name
        @configure_block = configure_block if block_given?
      end

      def self.submit_options(&submit_options_block)
        @submit_options_block = submit_options_block if block_given?
      end

      def self.on_submit(method_name = nil, &submit_block)
        @submit_block = block_given? ? submit_block : lambda {|env| self.send(method_name, env)}
      end

      def self.build_topology
        resolve_ids!(components)

        builder = TopologyBuilder.new
        spouts.each do |spout|
          declarer = builder.setSpout(spout.id, spout.new_instance, spout.parallelism.to_java)
          declarer.addConfigurations(spout.config)
        end
        bolts.each do |bolt|
          declarer = builder.setBolt(bolt.id, bolt.new_instance, bolt.parallelism.to_java)
          declarer.addConfigurations(bolt.config)
          bolt.define_grouping(declarer)
        end
        builder.createTopology
      end

      def start(env)
        topology = self.class.build_topology

        # set the JRuby compatibility mode option for Storm workers, default to current JRuby mode
        defaults = {"topology.worker.childopts" => "-Djruby.compat.version=#{RedStorm.jruby_mode_token}"}

        configurator = Configurator.new(defaults)
        configurator.instance_exec(env, &self.class.configure_block)

        submitter = (env == :local) ? @cluster = LocalCluster.new : StormSubmitter

        if self.class.submit_options_block && env != :local
          submit_options = SubmitOptions.new
          submit_options.instance_exec(env, &self.class.submit_options_block)

          submitter.submitTopology(self.class.topology_name, configurator.config, topology, submit_options)
        else
          submitter.submitTopology(self.class.topology_name, configurator.config, topology)
        end

        instance_exec(env, &self.class.submit_block)
      end

      private

      # this is a quirk to figure out the topology class at load time when the topology file
      # is required in the TopologyLauncher. Since we want to make the "configure" DSL statement
      # optional we can hook into any/all the other DSL statements that will be called at load time
      # and set it there. This is somewhat inelegant but it works.
      def self.set_topology_class!
        Configuration.topology_class = self
      end

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

      def self.submit_options_block
        @submit_options_block
      end

      def self.submit_block
        @submit_block ||= lambda{|env|}
      end

      def self.underscore(camel_case)
        camel_case.to_s.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase!
      end
    end
  end

  # for backward compatibility
  SimpleTopology = DSL::Topology

end
