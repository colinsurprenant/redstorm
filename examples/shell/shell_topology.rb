require 'red_storm'
require 'thread'

java_import 'redstorm.storm.jruby.JRubyShellBolt'

class SimpleSpout < RedStorm::SimpleSpout
  on_init do
    @q = Queue.new
    @q << "the quick red fox"
  end

  on_send do
    # avoid putting the thread to sleep endlessly on @q.pop which will prevent local cluster.shutdown
    sleep(1)
    @q.pop unless @q.empty?
  end
end

class ShellTopology < RedStorm::SimpleTopology
  spout SimpleSpout do
    output_fields :string
  end

  bolt JRubyShellBolt, ["python", "splitsentence.py"] do
    output_fields "word"
    source SimpleSpout, :shuffle
  end

  configure do |env|
    debug true
  end

  on_submit do |env|
    case env
    when :local
      sleep(10)
      cluster.shutdown
    end
  end
end

