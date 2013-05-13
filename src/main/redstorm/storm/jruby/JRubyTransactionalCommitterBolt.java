package redstorm.storm.jruby;

import backtype.storm.coordination.IBatchBolt;
import backtype.storm.transactional.TransactionAttempt;
import backtype.storm.transactional.ICommitter;

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
public class JRubyTransactionalCommitterBolt extends JRubyTransactionalBolt implements ICommitter {
  public JRubyTransactionalCommitterBolt(String baseClassPath, String realBoltClassName, String[] fields) {
    super(baseClassPath, realBoltClassName, fields);
  }

  private static IBatchBolt newProxyBolt(String baseClassPath, String realBoltClassName) {
    try {
      redstorm.proxy.BatchCommitterBolt proxy = new redstorm.proxy.BatchCommitterBolt(baseClassPath, realBoltClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}