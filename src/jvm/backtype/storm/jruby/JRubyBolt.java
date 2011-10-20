package backtype.storm.jruby;

import backtype.storm.task.OutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichBolt;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Tuple;
import java.util.Map;

/**
 * the JRubyBolt class is a simple proxy class to the actual bolt implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization process when dispatching
 * the bolts to the workers. JRuby does not yet support serialization from Java
 * (Java serialization call on a JRuby class). 
 *
 * Note that the JRuby bolt class is instanciated twice, in the constructor and in the prepare
 * method. The constructor instance is required to support the declareOutputFields at topology
 * creation while the prepare instance is required for the actual bolt execution, 
 * post-deserialization at the workers.
 */
public class JRubyBolt implements IRichBolt {
  IRichBolt _bolt;
  String _jrubyClassName;
  
  /**
   * create a new JRubyBolt
   * 
   * @param jrubyClassName the fully qualified JRuby bolt implementation class name
   */
  public JRubyBolt(String jrubyClassName) {
    // create instance of the jruby class so its available for declareOutputFields 
    // which gets executed in the topology creation time, before the prepare method 
    _jrubyClassName = jrubyClassName;
    _bolt = realJRubyBolt(_jrubyClassName);
  }

  @Override
  public void prepare(final Map stormConf, final TopologyContext context, final OutputCollector collector) {
    // create instance of the jruby class here, after deserialization for the workers.
    _bolt = realJRubyBolt(_jrubyClassName);
    _bolt.prepare(stormConf, context, collector);
  }

  @Override
  public void execute(Tuple input) {
    _bolt.execute(input);
  }

  @Override
  public void cleanup() {
    _bolt.cleanup();
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    _bolt.declareOutputFields(declarer);
  }

  private static IRichBolt realJRubyBolt(String realClassName) {
    try {
      Class clazz = Class.forName(realClassName);
      return (IRichBolt)clazz.newInstance();
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
