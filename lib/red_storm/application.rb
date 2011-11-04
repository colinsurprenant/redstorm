require 'rake'

class RedStorm::Application 

  def run(args)
    load("#{RedStorm::REDSTORM_HOME}/Rakefile")

    if args.size == 1 && File.exist?(args.first)
      Rake::Task['launch'].invoke(args)
    else
      Rake::Task[args.shift].invoke(args)
    end
  end

end