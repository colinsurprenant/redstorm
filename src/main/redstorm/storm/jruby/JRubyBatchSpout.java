package redstorm.storm.jruby;

import backtype.storm.tuple.Fields;
import backtype.storm.task.TopologyContext;
import storm.trident.operation.TridentCollector;
import storm.trident.spout.IBatchSpout;
import java.util.Map;

/**
 * the JRubySpout class is a simple proxy class to the actual spout implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization process when dispatching
 * the spout to the workers. JRuby does not yet support serialization from Java
 * (Java serialization call on a JRuby class). 
 *
 * Note that the JRuby spout proxy class is instanciated in the open method which is called after 
 * deserialization at the worker and in both the declareOutputFields and isDistributed methods which 
 * are called once before serialization at topology creation. 
 */
public class JRubyBatchSpout implements IBatchSpout {
  IBatchSpout _proxySpout;
  String _realSpoutClassName;
  String _baseClassPath;
  
  /**
   * create a new JRubySpout
   * 
   * @param baseClassPath the topology/project base JRuby class file path 
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   */
  public JRubyBatchSpout(String baseClassPath, String realSpoutClassName) {
    _baseClassPath = baseClassPath;
    _realSpoutClassName = realSpoutClassName;
  }

  @Override
  public void open(final Map conf, final TopologyContext context) {
    // create instance of the jruby proxy class here, after deserialization in the workers.
    _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    _proxySpout.open(conf, context);
  }

  @Override
  public void emitBatch(long batchId, TridentCollector collector) {
    _proxySpout.emitBatch(batchId, collector);
  } 

  @Override
  public void close() {
    _proxySpout.close();
  }

  @Override
  public void ack(long batchId) {
    _proxySpout.ack(batchId);
  }

  @Override
  public Fields getOutputFields() {
    if (_proxySpout == null) {
      // getOutputFields is executed in the topology creation time before serialisation.
      // do not set the _proxySpout instance variable here to avoid JRuby serialization
      // issues. Just create tmp spout instance to call getOutputFields.
      IBatchSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
      return spout.getOutputFields();
    } else {
      return _proxySpout.getOutputFields();
    }
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time before serialisation.
    // do not set the _proxySpout instance variable here to avoid JRuby serialization
    // issues. Just create tmp spout instance to call declareOutputFields.
    IBatchSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
    return spout.getComponentConfiguration();
  }
 
  private static IBatchSpout newProxySpout(String baseClassPath, String realSpoutClassName) {
    try {
      redstorm.proxy.BatchSpout proxy = new redstorm.proxy.BatchSpout(baseClassPath, realSpoutClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
