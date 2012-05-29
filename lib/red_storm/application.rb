module RedStorm

  DEFAULT_RUBY_VERSION = "--1.8"
  RUNTIME = {}
  
  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def usage
      puts("usage: redstorm install|gems|examples|jar <project_directory>|local <topology_class_file>")
      exit(1)
    end

    def run(args)
      if args.size > 0
        version = args.delete("--1.8") || args.delete("--1.9") || DEFAULT_RUBY_VERSION
        RUNTIME['RUBY_VERSION'] = version

        if ["install", "examples", "jar", "gems", "deps", "build"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(*args)
          exit
        elsif args.size >= 2 && args.include?("local") 
          args.delete("local")
          if args.size == 1
            file = args[0]
            load(TASKS_FILE)
            Rake::Task['launch'].invoke("local", file)
            exit
          end
        end
      end
      usage
    end
  end
end