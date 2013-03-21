package redstorm.storm.jruby;

import backtype.storm.task.ShellBolt;
import backtype.storm.topology.IRichBolt;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Fields;
import java.util.Map;
    
public class JRubyShellBolt  extends ShellBolt  implements IRichBolt {
  private String[] _fields;

  public JRubyShellBolt(String[] command, String[] fields) {
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
