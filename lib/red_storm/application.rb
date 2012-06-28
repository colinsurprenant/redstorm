module RedStorm
  
  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def usage
      puts("usage: redstorm install")
      puts("       redstorm deps")
      puts("       redstorm build")
      puts("       redstorm examples")
      puts("       redstorm bundle [BUNDLER_GROUP]")
      puts("       redstorm jar DIR1, [DIR2, ...]")
      puts("       redstorm local [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      puts("       redstorm cluster [--1.8|--1.9] TOPOLOGY_CLASS_PATH")
      exit(1)
    end

    def run(args)
      if args.size > 0
        if ["install", "examples", "jar", "bundle", "deps", "build"].include?(args[0])
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
  end

end