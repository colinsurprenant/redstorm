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

@redis = Redis.new(:host => "localhost", :port => 6379)
@redis.del(topology_class)

command = RedStorm::Application.local_storm_command(topology_class_path)
pid = spawn("#{command} > /dev/null", :out=>"/dev/null")

result = @redis.blpop(topology_class, :timeout => 30)
sleep(5) if result

if result.nil? || result[1] != "SUCCESS"
  puts("FAILED, bad result=#{result.inspect}")
  exit(1)
end
puts("SUCCESS")
