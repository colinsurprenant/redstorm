require 'rubygems'
# require 'bundler/setup'

begin
  # will work from gem, since lib dir is in gem require_paths
  require 'red_storm/application'
rescue LoadError
  # will work within RedStorm dev project
  $:.unshift './lib'
  begin
    require 'red_storm/application'
  rescue LoadError
    require 'bundler/setup'
    require 'red_storm/application'
  end
end

require 'redis'

topology_class_path = ARGV[0]
topology_class = topology_class_path.split("/").last

@redis = Redis.new(:host => "localhost", :port => 6379)
@redis.del(topology_class)

command = RedStorm::Application.local_storm_command(topology_class_path)

success, out = RedStorm::Application.subshell(RedStorm::Application.local_storm_command(topology_class_path))
puts("storm FAILED\n\n#{out}") unless success

result = @redis.blpop(topology_class, :timeout => 30)
sleep(5) if result

if result.nil? || result[1] != "SUCCESS"
  puts("test FAILED, bad result=#{result.inspect}")
  exit(1)
end
puts("SUCCESS")
