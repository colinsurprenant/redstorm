module RedStorm
  REDSTORM_HOME = File.expand_path(File.dirname(__FILE__) + '/..') unless defined?(REDSTORM_HOME)
end

require 'red_storm/version'
require 'red_storm/application'
