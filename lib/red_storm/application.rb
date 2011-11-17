module RedStorm
  
  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def usage
      puts("usage: redstorm install|examples|jar <project_directory>|local <topology_class_file>")
      exit(1)
    end

    def run(args)
      if args.size > 0
        if ["install", "examples", "jar"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(*args)
        elsif args.size == 2 && ["local"].include?(args[0]) && File.exist?(args[1])
          load(TASKS_FILE)
          Rake::Task['launch'].invoke(*args)
        else
          usage
        end
      else
        usage
      end
    end
  end
end