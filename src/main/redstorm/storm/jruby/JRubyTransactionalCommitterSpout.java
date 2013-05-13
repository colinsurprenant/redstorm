package redstorm.storm.jruby;

import backtype.storm.transactional.ICommitterTransactionalSpout;
import backtype.storm.transactional.ITransactionalSpout;
import backtype.storm.task.TopologyContext;
import java.util.Map;

/**
 * the JRubyBolt class is a simple proxy class to the actual bolt implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization process when dispatching
 * the bolts to the workers. JRuby does not yet support serialization from Java
 * (Java serialization call on a JRuby class). 
 *
 * Note that the JRuby bolt proxy class is instanciated in the prepare method which is called after 
 * deserialization at the worker and in the declareOutputFields method which is called once before 
 * serialization at topology creation. 
 */
public class JRubyTransactionalCommitterSpout extends JRubyTransactionalSpout implements ICommitterTransactionalSpout {

  ICommitterTransactionalSpout _proxySpout;
  
  public JRubyTransactionalCommitterSpout(String baseClassPath, String realSpoutClassName, String[] fields) {
    super(baseClassPath, realSpoutClassName, fields);
  }

  @Override
  public ICommitterTransactionalSpout.Emitter getEmitter(Map conf, TopologyContext context) {
    // create instance of the jruby class here, after deserialization in the workers.
    if (_proxySpout == null) {
      _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    }
    return _proxySpout.getEmitter(conf, context);
  }

  private static ICommitterTransactionalSpout newProxySpout(String baseClassPath, String realSpoutClassName) {
    try {
      redstorm.proxy.TransactionalCommitterSpout proxy = new redstorm.proxy.TransactionalCommitterSpout(baseClassPath, realSpoutClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}