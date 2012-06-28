module RedStorm
  
  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def usage
      puts("usage: redstorm install | deps | build | examples | gems | bundle [BUNDLER_GROUP] | jar DIR1, [DIR2, ...] | local [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      exit(1)
    end

    def run(args)
      if args.size > 0
        if ["install", "examples", "jar", "gems", "bundle", "deps", "build"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(args.join(":"))
          exit
        elsif args.size >= 2 && (args.include?("local") || args.include?("cluster"))
          env = args.delete("local") || args.delete("cluster")
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
  end

end