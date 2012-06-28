module RedStorm

  LAUNCH_PATH = File.expand_path(File.dirname(__FILE__))
  JAR_CONTEXT = !!(LAUNCH_PATH =~ /\.jar!\/red_storm$/)

  if JAR_CONTEXT
    BASE_PATH = File.expand_path(LAUNCH_PATH + '/..')
    REDSTORM_HOME = BASE_PATH
    TARGET_PATH = BASE_PATH
  else
    BASE_PATH = Dir.pwd
    REDSTORM_HOME = File.expand_path(LAUNCH_PATH + '/../..')
    TARGET_PATH = "#{BASE_PATH}/target"
  end
  
  unless defined?(SPECS_CONTEXT)
    GEM_PATH = "#{TARGET_PATH}/gems/"
    ENV["GEM_PATH"] = GEM_PATH
    ENV["GEM_HOME"] = GEM_PATH
  end

  def current_ruby_mode
    RUBY_VERSION =~ /(\d+\.\d+)(\.\d+)*/
    raise("unknown Ruby version #{$1}") unless $1 == "1.8" || $1 == "1.9"
    $1
  end

  def jruby_mode_token(ruby_version = nil)
    version_map = {"1.8" => "RUBY1_8", "--1.8" => "RUBY1_8", "1.9" => "RUBY1_9", "--1.9" => "RUBY1_9"}
    version_map[ruby_version.to_s] || version_map[RedStorm.current_ruby_mode]
  end

  module_function :current_ruby_mode, :jruby_mode_token

  # puts("*** LAUNCH_PATH=#{LAUNCH_PATH}")
  # puts("*** JAR_CONTEXT=#{JAR_CONTEXT}")
  # puts("*** BASE_PATH=#{BASE_PATH}")
  # puts("*** REDSTORM_HOME=#{REDSTORM_HOME}")
  # puts("*** TARGET_PATH=#{TARGET_PATH}")
  # puts("*** GEM_PATH=#{GEM_PATH}") if defined?(GEM_PATH)
end
