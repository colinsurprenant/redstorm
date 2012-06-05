# this is the entry point for these two contexts:
# - running red_storm.rake
# - at remote cluster topology execution. Once topology_launcher.rb has submitted the topology
#   the spouts and bolts classes will be instanciated and will require red_storm.rb

# we depends on rubygems begings loaded at this point for setting up gem/bundle environments
# explicitely requiring rubygems is required in remote cluster environment
require 'rubygems'


module RedStorm
  TOPOLOGY_LAUNCHED = defined?(LAUNCH_PATH)

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

puts("**** red_storm ** PRE PWD=#{Dir.pwd}")
puts("**** red_storm ** PRE RedStorm::JAR_CONTEXT=#{RedStorm::JAR_CONTEXT}")
puts("**** red_storm ** PRE RedStorm::LAUNCH_PATH=#{RedStorm::LAUNCH_PATH}")
puts("**** red_storm ** PRE RedStorm::BASE_PATH=#{RedStorm::BASE_PATH}")


unless RedStorm::JAR_CONTEXT
  puts("red_storm UNSHIFTING #{RedStorm::BASE_PATH}/lib")
  $:.unshift "#{RedStorm::BASE_PATH}/lib" 
end

unless RedStorm::TOPOLOGY_LAUNCHED
  require 'red_storm/environment'
  # setup gems env only in JAR context otherwise it has already been setup
  # in topology_launcher.rb 
  RedStorm.setup_gems if RedStorm::JAR_CONTEXT
end

require 'red_storm/version'
require 'red_storm/configuration'
require 'red_storm/application'
require 'red_storm/simple_bolt'
require 'red_storm/simple_spout'
require 'red_storm/simple_topology'

puts("**** red_storm ** POST PWD=#{Dir.pwd}")
puts("**** red_storm ** POST edStorm::JAR_CONTEXT=#{RedStorm::JAR_CONTEXT}")
puts("**** red_storm ** POST RedStorm::LAUNCH_PATH=#{RedStorm::LAUNCH_PATH}")
puts("**** red_storm ** POST RedStorm::REDSTORM_HOME=#{RedStorm::REDSTORM_HOME}")
puts("**** red_storm ** POST RedStorm::TARGET_PATH=#{RedStorm::TARGET_PATH}")
puts("**** red_storm ** POST RedStorm::GEM_PATH=#{RedStorm::GEM_PATH}")
puts("**** red_storm ** POST ENV['BUNDLE_GEMFILE']=#{ENV['BUNDLE_GEMFILE']}")
puts("**** red_storm ** POST ENV['BUNDLE_PATH']=#{ENV['BUNDLE_PATH']}")
puts("**** red_storm ** POST ENV['GEM_PATH']=#{ENV['GEM_PATH']}")
