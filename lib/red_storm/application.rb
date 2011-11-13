require 'rake'

module RedStorm
  
  class Application 
    TASKS_FILE = "#{RedStorm::REDSTORM_HOME}/lib/tasks/red_storm.rake" 

    def usage
      puts("Usage: redstorm install|examples|jar")
      puts("       redstorm local|cluster topology_class_file_name\n")
      exit(1)
    end

    def run(args)
      if args.size > 0
        if ["install", "examples", "jar"].include?(args[0])
          load(TASKS_FILE)
          Rake::Task[args.shift].invoke(*args)
        elsif args.size == 2 && ["local", "cluster"].include?(args[0]) && File.exist?(args[1])
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