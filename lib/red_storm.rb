module RedStorm
  REDSTORM_HOME = File.expand_path(File.dirname(__FILE__) + '/..') unless defined?(REDSTORM_HOME)
end

require 'red_storm/version'
require 'red_storm/configuration'
require 'red_storm/application'
require 'red_storm/simple_bolt'
require 'red_storm/simple_spout'
require 'red_storm/simple_topology'
