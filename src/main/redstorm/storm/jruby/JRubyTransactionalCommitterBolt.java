package redstorm.storm.jruby;

import backtype.storm.coordination.IBatchBolt;
import backtype.storm.transactional.TransactionAttempt;
import backtype.storm.transactional.ICommitter;

/**
 * the JRubyBolt class is a proxy class to the actual bolt implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization issues of JRuby objects.
 * JRuby classes do not support Java serialization.
 *
 * Note that the JRuby bolt class is instanciated in the prepare method which is called after
 * deserialization at the worker and in the declareOutputFields & getComponentConfiguration
 * methods which are called once before serialization at topology creation.
 */
public class JRubyTransactionalCommitterBolt extends JRubyTransactionalBolt implements ICommitter {
  public JRubyTransactionalCommitterBolt(String baseClassPath, String realBoltClassName, String[] fields) {
    super(baseClassPath, realBoltClassName, fields);
  }
}