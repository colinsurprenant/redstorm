require 'java'
require 'red_storm/configuration'
require 'red_storm/configurator'

module RedStorm

  class InputBoltDefinition < SimpleTopology::BoltDefinition

    def source(source_fields)
      @sources << source_fields
    end

    def define_grouping(declarer)
      @sources.each do |source_fields|
        declare.declare(Fields.new(*(Array.wrap(source_fields).map(&:to_s))))
      end
    end
  end

  class SimpleDRPCTopology < SimpleTopology

    def self.spout
      raise TopologyDefinitionError, "DRPC spout is already defined"
    end


    def start(base_class_path, env)
      # self.class.resolve_ids!(self.class.components)

      builder = LinearDRPCTopologyBuilder.new(self.class.topology_name)

      self.class.bolts.each do |bolt|
        declarer = builder.addBolt(bolt.new_instance(base_class_path), bolt.parallelism.to_java)
        #declarer.addConfigurations(bolt.config)
        #bolt.define_grouping(declarer)
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
