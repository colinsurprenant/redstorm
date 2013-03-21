package redstorm.storm.jruby;

import backtype.storm.spout.ShellSpout;
import backtype.storm.topology.IRichSpout;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Fields;
import java.util.Map;

public class JRubyShellSpout extends ShellSpout implements IRichSpout {
  private String[] _fields;

  public JRubyShellSpout(String[] command, String[] fields) {
    super(command);
    _fields = fields;
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    declarer.declare(new Fields(_fields));
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    return null;
  }
}
