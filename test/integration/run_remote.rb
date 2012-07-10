begin
  # will work from gem, since lib dir is in gem require_paths
  require 'red_storm/application'
rescue LoadError
  # will work within RedStorm dev project
  $:.unshift './lib'
  require 'red_storm/application'
end

require 'redis'

topology_class_path = ARGV[0]
topology_class = topology_class_path.split("/").last

@redis = Redis.new(:host => "localdevhost", :port => 6379)
@redis.del(topology_class)

command = RedStorm::Application.cluster_storm_command(topology_class_path)
unless system("#{command} > /dev/null")
  puts("FAILED, #{$!}")
  exit(1)
end

result = @redis.blpop(topology_class, :timeout => 60)

command = "storm kill #{topology_class.split(".").first} > /dev/null"
unless system(command)
  puts("FAILED, #{$!}")
  exit(1)
end

if result.nil? || result[1] != "SUCCESS"
  puts("FAILED, bad result=#{result.inspect}")
  exit(1)
end
puts("SUCCESS")
