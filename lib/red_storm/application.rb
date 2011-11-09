require 'rake'

module RedStorm
  
  class Application 

    def run(args)
      if args.size == 1 && File.exist?(args.first)
        load("#{RedStorm::REDSTORM_HOME}/Rakefile")
        Rake::Task['launch'].invoke(args)
      else
        task = args.shift
        if ["install", "examples", "jar"].include?(task)
          load("#{RedStorm::REDSTORM_HOME}/Rakefile")
          Rake::Task[task].invoke(args)
        else
          puts("\nUsage: redstorm install|examples|jar|topology_class_file_name")
          exit(1)
        end
      end
    end
  end
end