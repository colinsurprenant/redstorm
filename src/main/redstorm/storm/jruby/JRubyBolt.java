package redstorm.storm.jruby;

import backtype.storm.task.OutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichBolt;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Fields;
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
public class JRubyBolt implements IRichBolt {
  IRichBolt _proxyBolt;
  String _realBoltClassName;
  String _baseClassPath;
  String[] _fields;

  /**
   * create a new JRubyBolt
   * 
   * @param baseClassPath the topology/project base JRuby class file path 
   * @param realBoltClassName the fully qualified JRuby bolt implementation class name
   */
  public JRubyBolt(String baseClassPath, String realBoltClassName, String[] fields) {
    _baseClassPath = baseClassPath;
    _realBoltClassName = realBoltClassName;
    _fields = fields;
  }

  @Override
  public void prepare(final Map stormConf, final TopologyContext context, final OutputCollector collector) {
    // create instance of the jruby class here, after deserialization in the workers.
    _proxyBolt = newProxyBolt(_baseClassPath, _realBoltClassName);
    _proxyBolt.prepare(stormConf, context, collector);
  }

  @Override
  public void execute(Tuple input) {
    _proxyBolt.execute(input);
  }

  @Override
  public void cleanup() {
    _proxyBolt.cleanup();
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time, before serialisation.
    // do not set the _proxyBolt instance variable here to avoid JRuby serialization
    // issues. Just create tmp bolt instance to call declareOutputFields.
    if (_fields.length > 0) {
      declarer.declare(new Fields(_fields));
    } else {
      IRichBolt bolt = newProxyBolt(_baseClassPath, _realBoltClassName);
      bolt.declareOutputFields(declarer);
    }
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time, before serialisation.
    // do not set the _proxyBolt instance variable here to avoid JRuby serialization
    // issues. Just create tmp bolt instance to call declareOutputFields.
    IRichBolt bolt = newProxyBolt(_baseClassPath, _realBoltClassName);
    return bolt.getComponentConfiguration();
  }
 

  private static IRichBolt newProxyBolt(String baseClassPath, String realBoltClassName) {
    try {
      redstorm.proxy.Bolt proxy = new redstorm.proxy.Bolt(baseClassPath, realBoltClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
