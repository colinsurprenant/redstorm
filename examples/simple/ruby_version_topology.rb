require 'red_storm'

# this example topology only prints the Ruby version string. No tuple is emitted.

module RedStorm
  module Examples
    class VersionSpout < RedStorm::SimpleSpout
      output_fields :dummy
      on_init {log.info("****** JRuby version #{RUBY_VERSION}")}
      on_send {}
    end

    class RubyVersionTopology < RedStorm::SimpleTopology
      spout VersionSpout
            
      configure do |env|
        debug true

        # set the JRuby version property for this topology. this will only affect remote cluster execution
        # for local execution use the --1.8|--1.9 switch when launching
        set "topology.worker.childopts", "-Djruby.compat.version=RUBY1_9"
      end

      on_submit do |env|
        if env == :local
          sleep(1)
          cluster.shutdown
        end
      end
    end
  end
end