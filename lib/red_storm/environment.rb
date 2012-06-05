module RedStorm
  # LAUNCH_PATH, BASE_PATH and JAR_CONTEXT must be set before requiring this module
  # typically, they must be set in either red_storm.rb and topology_launcher.rd
  # which are the 2 entry points

  if JAR_CONTEXT
    REDSTORM_HOME = LAUNCH_PATH
    TARGET_PATH = LAUNCH_PATH
    BUNDLE_GEMFILE = "#{TARGET_PATH}/bundler/Gemfile"
    BUNDLE_PATH = "#{TARGET_PATH}/bundler/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}/"
    GEM_PATH = "#{TARGET_PATH}/gems/"
  else
    REDSTORM_HOME = File.expand_path(LAUNCH_PATH + '/..')
    TARGET_PATH = "#{BASE_PATH}/target"
    BUNDLE_GEMFILE = "#{TARGET_PATH}/gems/bundler/Gemfile"
    BUNDLE_PATH = "#{TARGET_PATH}/gems/bundler/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}/"
    GEM_PATH = "#{TARGET_PATH}/gems/gems"
  end

  def setup_gems
    ENV['BUNDLE_GEMFILE'] = RedStorm::BUNDLE_GEMFILE
    ENV['BUNDLE_PATH'] = RedStorm::BUNDLE_PATH
    ENV["GEM_PATH"] = RedStorm::GEM_PATH
    ENV['BUNDLE_DISABLE_SHARED_GEMS'] = "1"
  end

  module_function :setup_gems
end
