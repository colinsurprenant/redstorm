raise("rubygems must be loaded prior to loading red_storm") unless defined?(Gem)

module RedStorm
  LAUNCH_PATH = File.expand_path(File.dirname(__FILE__))
  JAR_CONTEXT = !!(LAUNCH_PATH =~ /\.jar!$/)

  if JAR_CONTEXT
    REDSTORM_HOME = LAUNCH_PATH
    TARGET_PATH = LAUNCH_PATH
    BUNDLE_GEMFILE = "#{TARGET_PATH}/Gemfile"
    BUNDLE_PATH = "#{TARGET_PATH}/bundler/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}/"
    GEM_PATH = "#{TARGET_PATH}/gems/"
  else
    REDSTORM_HOME = File.expand_path(LAUNCH_PATH + '/..')
    TARGET_PATH = Dir.pwd
    BUNDLE_GEMFILE = "#{TARGET_PATH}/Gemfile"
    BUNDLE_PATH = "#{TARGET_PATH}/target/gems/bundler/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}/"
    GEM_PATH = "#{TARGET_PATH}/target/gems/gems"
  end

  # setup bundler environment
  ENV['BUNDLE_GEMFILE'] = RedStorm::BUNDLE_GEMFILE
  ENV['BUNDLE_PATH'] = RedStorm::BUNDLE_PATH
  ENV["GEM_PATH"] = RedStorm::GEM_PATH
  ENV['BUNDLE_DISABLE_SHARED_GEMS'] = "1"  
end

require 'red_storm/version'
require 'red_storm/configuration'
require 'red_storm/application'
require 'red_storm/simple_bolt'
require 'red_storm/simple_spout'
require 'red_storm/simple_topology'


# puts("************************ PWD=#{Dir.pwd}")
# puts("************************ RedStorm::JAR_CONTEXT=#{RedStorm::JAR_CONTEXT}")
# puts("************************ RedStorm::LAUNCH_PATH=#{RedStorm::LAUNCH_PATH}")
# puts("************************ RedStorm::REDSTORM_HOME=#{RedStorm::REDSTORM_HOME}")
# puts("************************ RedStorm::TARGET_PATH=#{RedStorm::TARGET_PATH}")
# puts("************************ RedStorm::GEM_PATH=#{RedStorm::GEM_PATH}")
# puts("************************ ENV['BUNDLE_GEMFILE']=#{ENV['BUNDLE_GEMFILE']}")
# puts("************************ ENV['BUNDLE_PATH']=#{ENV['BUNDLE_PATH']}")
# puts("************************ ENV['GEM_PATH']=#{ENV['GEM_PATH']}")

