package redstorm.storm.jruby;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichSpout;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Fields;
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
public class JRubySpout implements IRichSpout {
  IRichSpout _proxySpout;
  String _realSpoutClassName;
  String _baseClassPath;
  String[] _fields;

  /**
   * create a new JRubySpout
   * 
   * @param baseClassPath the topology/project base JRuby class file path 
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   */
  public JRubySpout(String baseClassPath, String realSpoutClassName, String[] fields) {
    _baseClassPath = baseClassPath;
    _realSpoutClassName = realSpoutClassName;
    _fields = fields;
  }

  @Override
  public void open(final Map conf, final TopologyContext context, final SpoutOutputCollector collector) {
    // create instance of the jruby proxy class here, after deserialization in the workers.
    _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    _proxySpout.open(conf, context, collector);
  }

  @Override
  public void close() {
    _proxySpout.close();
  }

  @Override
  public void activate() {
    _proxySpout.activate();
  }

  @Override
  public void deactivate() {
    _proxySpout.deactivate();
  }

  @Override
  public void nextTuple() {
    _proxySpout.nextTuple();
  }

  @Override
  public void ack(Object msgId) {
    _proxySpout.ack(msgId);
  }

  @Override
  public void fail(Object msgId) {
    _proxySpout.fail(msgId);
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time before serialisation.
    // do not set the _proxySpout instance variable here to avoid JRuby serialization
    // issues. Just create tmp spout instance to call declareOutputFields.
    if (_fields.length > 0) {
      declarer.declare(new Fields(_fields));
    } else {
      IRichSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
      spout.declareOutputFields(declarer);
    }
  }  

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time before serialisation.
    // do not set the _proxySpout instance variable here to avoid JRuby serialization
    // issues. Just create tmp spout instance to call declareOutputFields.
    IRichSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
    return spout.getComponentConfiguration();
  }
 
  private static IRichSpout newProxySpout(String baseClassPath, String realSpoutClassName) {
    try {
      redstorm.proxy.Spout proxy = new redstorm.proxy.Spout(baseClassPath, realSpoutClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
