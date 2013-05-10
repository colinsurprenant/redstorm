package redstorm.storm.jruby;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;

import backtype.storm.topology.base.BaseTransactionalSpout;
import backtype.storm.transactional.ITransactionalSpout;

import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Tuple;
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
public class JRubyTransactionalSpout extends BaseTransactionalSpout {
  ITransactionalSpout _proxySpout;
  String _realSpoutClassName;
  String _baseClassPath;
  
  /**
   * create a new JRubySpout
   * 
   * @param baseClassPath the topology/project base JRuby class file path 
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   */
  public JRubyTransactionalSpout(String baseClassPath, String realSpoutClassName) {
    _baseClassPath = baseClassPath;
    _realSpoutClassName = realSpoutClassName;
  }

  @Override
  public Coordinator getCoordinator(Map conf, TopologyContext context) {
    // create instance of the jruby class here, after deserialization in the workers.
    if (_proxySpout == null) {
      _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    }
    return _proxySpout.getCoordinator(conf, context);
  }

  @Override
  public Emitter getEmitter(Map conf, TopologyContext context) {
    // create instance of the jruby class here, after deserialization in the workers.
  	if (_proxySpout == null) {
      _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    }
    return _proxySpout.getEmitter(conf, context);
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time before serialisation.
    // do not set the _proxySpout instance variable here to avoid JRuby serialization
    // issues. Just create tmp spout instance to call declareOutputFields.
    ITransactionalSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
    spout.declareOutputFields(declarer);
  }  

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time before serialisation.
    // do not set the _proxySpout instance variable here to avoid JRuby serialization
    // issues. Just create tmp spout instance to call declareOutputFields.
    ITransactionalSpout spout = newProxySpout(_baseClassPath, _realSpoutClassName);
    return spout.getComponentConfiguration();
  }
 
  private static ITransactionalSpout newProxySpout(String baseClassPath, String realSpoutClassName) {
    try {
      redstorm.proxy.TransactionalSpout proxy = new redstorm.proxy.TransactionalSpout(baseClassPath, realSpoutClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
