require 'java'
require 'red_storm/configuration'
require 'red_storm/configurator'

module RedStorm

  class InputBoltDefinition < SimpleTopology::BoltDefinition
    attr_accessor :grouping

    def initialize(*args)
      super
      @grouping = :none
    end

    def grouping(grouping)
      @grouping = @grouping
    end

    def define_grouping(declarer)

      case @grouping
      when :fields
        declarer.fieldsGrouping(Fields.new(*([params].flatten.map(&:to_s))))
      when :global
        declarer.globalGrouping()
      when :shuffle
        declarer.shuffleGrouping()
      when :local_or_shuffle
        declarer.localOrShuffleGrouping()
      when :none
        declarer.noneGrouping()
      when :all
        declarer.allGrouping()
      when :direct
        declarer.directGrouping()
      else
        raise("unknown grouper=#{grouper.inspect}")
      end
    end
  end

  class SimpleDRPCTopology < SimpleTopology

    def self.spout
      raise TopologyDefinitionError, "DRPC spout is already defined"
    end

    def start(base_class_path, env)
      builder = Java::BacktypeStormDrpc::LinearDRPCTopologyBuilder.new(self.class.topology_name)

      self.class.bolts.each do |bolt|
        declarer = builder.addBolt(bolt.new_instance(base_class_path), bolt.parallelism.to_java)
        declarer.addConfigurations(bolt.config)
        bolt.define_grouping(declarer)
      end

      # set the JRuby compatibility mode option for Storm workers, default to current JRuby mode
      defaults = {"topology.worker.childopts" => "-Djruby.compat.version=#{RedStorm.jruby_mode_token}"}

      configurator = Configurator.new(defaults)
      configurator.instance_exec(env, &self.class.configure_block)

      drpc = nil
      if env == :local
        drpc = LocalDRPC.new
        submitter = @cluster = LocalCluster.new
        submitter.submitTopology(self.class.topology_name, configurator.config, builder.createLocalTopology(drpc))
      else
        submitter = StormSubmitter
        submitter.submitTopology(self.class.topology_name, configurator.config, builder.createRemoteTopology)
      end
      instance_exec(env, drpc, &self.class.submit_block)
    end

    def self.input_bolt(bolt_class, *args, &bolt_block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      contructor_args = !args.empty? ? args.pop : []
      bolt_options = {:id => self.underscore(bolt_class), :parallelism => DEFAULT_BOLT_PARALLELISM}.merge(options)

      bolt = InputBoltDefinition.new(bolt_class, contructor_args, bolt_options[:id], bolt_options[:parallelism])
      raise(TopologyDefinitionError, "#{bolt.clazz.name}, #{bolt.id}, bolt definition body required") unless block_given?
      bolt.instance_exec(&bolt_block)
      self.components << bolt
    end
  end

end
