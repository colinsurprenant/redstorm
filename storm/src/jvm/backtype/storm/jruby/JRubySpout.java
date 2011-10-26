package backtype.storm.jruby;

import backtype.storm.generated.StreamInfo;
import backtype.storm.spout.ISpout;
import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichSpout;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Fields;
import backtype.storm.utils.Utils;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * the JRubySpout class is a simple proxy class to the actual spout implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization process when dispatching
 * the spout to the workers. JRuby does not yet support serialization from Java
 * (Java serialization call on a JRuby class). 
 *
 * Note that the JRuby spout class is instanciated twice, in the constructor and in the open
 * method. The constructor instance is required to support the declareOutputFields at topology
 * creation while the open instance is required for the actual spout execution, 
 * post-deserialization at the workers.
 */
public class JRubySpout implements IRichSpout {
  IRichSpout _proxySpout;
  String _realSpoutClassName;
  
  /**
   * create a new JRubySpout
   * 
   * @param jrubyClassName the fully qualified JRuby spout implementation class name
   */
  public JRubySpout(String realSpoutClassName) {
    _realSpoutClassName = realSpoutClassName;
  }

  @Override
  public boolean isDistributed() {
    IRichSpout spout = newProxySpout(_realSpoutClassName);
    return spout.isDistributed();
  }

  @Override
  public void open(final Map conf, final TopologyContext context, final SpoutOutputCollector collector) {
    _proxySpout = newProxySpout(_realSpoutClassName);
    _proxySpout.open(conf, context, collector);
  }

  @Override
  public void close() {
    _proxySpout.close();
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
    IRichSpout spout = newProxySpout(_realSpoutClassName);
    spout.declareOutputFields(declarer);
  }  

  private static IRichSpout newProxySpout(String realSpoutClassName) {
    try {
      redstorm.proxy.Spout proxy = new redstorm.proxy.Spout(realSpoutClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
