require 'red_storm/version'
require 'red_storm/environment'


module RedStorm

  class Application
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake"

    def self.local_storm_command(class_file, ruby_mode = nil)
      src_dir = File.expand_path(File.dirname(class_file))
      "java -server -Djruby.compat.version=#{RedStorm.jruby_mode_token(ruby_mode)} -cp \"#{TARGET_CLASSES_DIR}:#{TARGET_DEPENDENCY_DIR}/storm/default/*:#{TARGET_DEPENDENCY_DIR}/topology/default/*:#{src_dir}/\" redstorm.TopologyLauncher local #{class_file}"
    end

    def self.cluster_storm_command(storm_conf, class_file, ruby_mode = nil)
      "java -client -Dstorm.conf.file=#{File.basename(storm_conf)} -Dstorm.jar=#{TARGET_CLUSTER_JAR} -Djruby.compat.version=#{RedStorm.jruby_mode_token(ruby_mode)} -cp #{TARGET_DEPENDENCY_DIR}/storm/default/*:#{TARGET_CLUSTER_JAR}:#{File.dirname(storm_conf)} redstorm.TopologyLauncher cluster #{class_file}"
    end

    def self.usage
      puts("usage: redstorm version")
      puts("       redstorm install [--JVM_VERSION] (ex.: --1.6 or --1.7) default is current JVM version")
      puts("       redstorm deps")
      puts("       redstorm build [--JVM_VERSION] (ex.: --1.6 or --1.7) default is current JVM version")
      puts("       redstorm examples")
      puts("       redstorm bundle [BUNDLER_GROUP]")
      puts("       redstorm jar DIR1, [DIR2, ...]")
      puts("       redstorm local [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      puts("       redstorm cluster [--1.8|--1.9] [--config STORM_CONFIG_PATH] TOPOLOGY_CLASS_PATH")
      exit(1)
    end

    # TODO: refactor args parsing... becoming a mess.

    def self.run(args)
      if args.size > 0
        if args[0] == "version"
          puts("RedStorm v#{VERSION}")
          exit
        elsif ["examples", "jar", "bundle", "deps", "install", "build"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(args.join(":"))
          exit
        elsif args.size >= 2 && ["local", "cluster"].include?(args[0])
          env = args.delete_at(0)
          version = args.delete("--1.8") || args.delete("--1.9")
          storm_conf = args.delete("--config") ? File.expand_path(args.delete_at(0)) : DEFAULT_STORM_CONF_FILE
          if args.size == 1
            file = args[0]
            load(TASKS_FILE)
            Rake::Task['launch'].invoke(env, storm_conf, version, file)
            exit
          end
        end
      end
      usage
    end

    def self.subshell(command)
      out = IO.popen(command, STDERR => STDOUT) {|io| io.read}
      [!!$?.success?, out]
    end

  end

end
