package redstorm.storm.jruby;

import java.util.Map;
import backtype.storm.task.TopologyContext;
import storm.trident.operation.TridentCollector;
import backtype.storm.tuple.Fields;
import storm.trident.spout.IBatchSpout;

public class JRubyBatchSpout implements IBatchSpout {
  IBatchSpout _proxy;
  String _realClassName;
  String _baseClassPath;
  String[] _fields;

  public JRubyBatchSpout(final String baseClassPath, final String realClassName, final String[] fields) {
    _baseClassPath = baseClassPath;
    _realClassName = realClassName;
    _fields = fields;
  }


  @Override
  public void open(final Map _map, final TopologyContext _topologyContext) {
    
    _proxy = newProxy(_baseClassPath, _realClassName);
    _proxy.open(_map, _topologyContext);
    
  }

  @Override
  public void close() {
    
    _proxy.close()
    
  }

  @Override
  public void ack(final long _long) {
    
    _proxy.ack(_long)
    
  }

  @Override
  public void emitBatch(final long _long, final TridentCollector _tridentCollector) {
    
    _proxy.emitBatch(_long, _tridentCollector)
    
  }

  @Override
  public Map getComponentConfiguration() {
    
    _proxy.getComponentConfiguration()
    
  }

  @Override
  public Fields getOutputFields() {
    
    _proxy.getOutputFields()
    
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    newProxy(_baseClassPath, _realClassName).getComponentConfiguration();
  }

  private static IBatchSpout newProxy(String baseClassPath, String realClassName) {
    try {
      redstorm.proxy.BatchSpout proxy = new redstorm.proxy.BatchSpout(baseClassPath, realClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
