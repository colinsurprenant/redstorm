require 'rake'

module RedStorm
  
  class Application 

    def usage
      puts("Usage: redstorm install|examples|jar")
      puts("       redstorm local|cluster topology_class_file_name\n")
      exit(1)
    end

    def run(args)
      if args.size > 0

        if ["install", "examples", "jar"].include?(args[0])
          task = args.shift
          load("#{RedStorm::REDSTORM_HOME}/Rakefile")
          Rake::Task[task].invoke(args)
        elsif args.size == 2 && ["local", "cluster"].include?(args[0]) && File.exist?(args[1])
          load("#{RedStorm::REDSTORM_HOME}/Rakefile")
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