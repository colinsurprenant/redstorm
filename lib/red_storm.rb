# this is the entry point for these two contexts:
# - running red_storm.rake
# - at remote cluster topology execution. Once topology_launcher.rb has submitted the topology
#   the spouts and bolts classes will be instanciated and will require red_storm.rb

# we depends on rubygems begings loaded at this point for setting up gem/bundle environments
# explicitely requiring rubygems is required in remote cluster environment
require 'rubygems'

# setup some environment constants
# this is required here and in topology_launcher.rb which are both 
# entry points in redstorm. 
module RedStorm
  TOPOLOGY_LAUNCHED = defined?(LAUNCH_PATH)

  # do not redefine if already defined in topology_launcher.rb
  unless TOPOLOGY_LAUNCHED
    LAUNCH_PATH = File.expand_path(File.dirname(__FILE__))
    JAR_CONTEXT = !!(LAUNCH_PATH =~ /\.jar!$/)

    if JAR_CONTEXT
      BASE_PATH = LAUNCH_PATH
    else
      BASE_PATH = Dir.pwd
    end
  end
end

unless RedStorm::JAR_CONTEXT
  # in JAR context red_storm.rb and red_storm/* is in the JAR root.
  # otherwise this is in lib/...
  $:.unshift "#{RedStorm::BASE_PATH}/lib" 
end

unless RedStorm::TOPOLOGY_LAUNCHED
  require 'red_storm/environment'
  RedStorm.setup_gems if RedStorm::JAR_CONTEXT
end

require 'red_storm/version'
require 'red_storm/configuration'
require 'red_storm/application'
require 'red_storm/simple_bolt'
require 'red_storm/simple_spout'
require 'red_storm/simple_topology'
