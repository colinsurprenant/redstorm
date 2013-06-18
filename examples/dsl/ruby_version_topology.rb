require 'java'
require 'red_storm'
java_import 'java.lang.System'


# this example topology only prints the Ruby version string. No tuple is emitted.

module RedStorm
  module Examples
    class VersionSpout < DSL::Spout
      output_fields :dummy
      on_init do
        log.info("***************** REDSTORM VERSION=#{VERSION}")
        log.info("***************** RUBY_VERSION=#{RUBY_VERSION}")
        log.info("***************** JRUBY_VERSION=#{JRUBY_VERSION}")
        log.info("***************** RUBY_ENGINE=#{RUBY_ENGINE}")
        log.info("***************** RUBY_PLATFORM=#{RUBY_PLATFORM}")
        log.info("***************** JAVA VERSION=#{System.properties["java.runtime.version"]}")
      end
      on_send {}
    end

    class RubyVersionTopology < DSL::Topology
      spout VersionSpout

      configure do |env|
        debug false
      end

      on_submit do |env|
        if env == :local
          sleep(5)
          cluster.shutdown
        end
      end
    end
  end
end