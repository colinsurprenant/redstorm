require 'red_storm/version'
require 'red_storm/environment'

CWD = Dir.pwd
TARGET_DIR = "#{CWD}/target"
TARGET_LIB_DIR = "#{TARGET_DIR}/lib"
TARGET_SRC_DIR = "#{TARGET_DIR}/src"
TARGET_GEM_DIR = "#{TARGET_DIR}/gems/gems"
TARGET_SPECS_DIR = "#{TARGET_DIR}/gems/specifications"
TARGET_CLASSES_DIR = "#{TARGET_DIR}/classes"
TARGET_DEPENDENCY_DIR = "#{TARGET_DIR}/dependency"
TARGET_DEPENDENCY_UNPACKED_DIR = "#{TARGET_DIR}/dependency-unpacked"
TARGET_CLUSTER_JAR = "#{TARGET_DIR}/cluster-topology.jar"

REDSTORM_JAVA_SRC_DIR = "#{RedStorm::REDSTORM_HOME}/src/main"
REDSTORM_LIB_DIR = "#{RedStorm::REDSTORM_HOME}/lib"

SRC_EXAMPLES = "#{RedStorm::REDSTORM_HOME}/examples"
DST_EXAMPLES = "#{CWD}/examples"

SRC_IVY_DIR = "#{RedStorm::REDSTORM_HOME}/ivy"
DST_IVY_DIR = "#{CWD}/ivy"
DEFAULT_IVY_SETTINGS = "#{SRC_IVY_DIR}/settings.xml"
CUSTOM_IVY_SETTINGS = "#{DST_IVY_DIR}/settings.xml"
DEFAULT_IVY_STORM_DEPENDENCIES = "#{SRC_IVY_DIR}/storm_dependencies.xml"
CUSTOM_IVY_STORM_DEPENDENCIES = "#{DST_IVY_DIR}/storm_dependencies.xml"
DEFAULT_IVY_TOPOLOGY_DEPENDENCIES = "#{SRC_IVY_DIR}/topology_dependencies.xml"
CUSTOM_IVY_TOPOLOGY_DEPENDENCIES = "#{DST_IVY_DIR}/topology_dependencies.xml"

module RedStorm

  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def self.local_storm_command(class_file, ruby_mode = nil)
      src_dir = File.expand_path(File.dirname(class_file))
      "java -Djruby.compat.version=#{RedStorm.jruby_mode_token(ruby_mode)} -cp \"#{TARGET_CLASSES_DIR}:#{TARGET_DEPENDENCY_DIR}/storm/default/*:#{TARGET_DEPENDENCY_DIR}/topology/default/*:#{src_dir}/\" redstorm.TopologyLauncher local #{class_file}"
    end

    def self.cluster_storm_command(class_file, ruby_mode = nil)
      "storm jar #{TARGET_CLUSTER_JAR} -Djruby.compat.version=#{RedStorm.jruby_mode_token(ruby_mode)} redstorm.TopologyLauncher cluster #{class_file}"
    end

    def self.usage
      puts("usage: redstorm version")
      puts("       redstorm install")
      puts("       redstorm deps")
      puts("       redstorm build")
      puts("       redstorm examples")
      puts("       redstorm bundle [BUNDLER_GROUP]")
      puts("       redstorm jar DIR1, [DIR2, ...]")
      puts("       redstorm local [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      puts("       redstorm cluster [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      exit(1)
    end

    def self.run(args)
      if args.size > 0
        if args[0] == "version"
          puts("RedStorm v#{VERSION}")
          exit
        elsif ["install", "examples", "jar", "bundle", "deps", "build"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(args.join(":"))
          exit
        elsif args.size >= 2 && ["local", "cluster"].include?(args[0])
          env = args.delete_at(0)
          version = args.delete("--1.8") || args.delete("--1.9")
          if args.size == 1
            file = args[0]
            load(TASKS_FILE)
            Rake::Task['launch'].invoke(env, version, file)
            exit
          end
        end
      end
      usage
    end

    def self.subshell(command)
      out = IO.popen(command, {:err => [:child, :out]}) {|io| io.read}
      [!!$?.success?, out]
    end

  end

end
