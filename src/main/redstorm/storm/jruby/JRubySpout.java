package redstorm.storm.jruby;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichSpout;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Fields;
import java.util.Iterator;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;

/**
 * the JRubySpout class is a proxy class to the actual spout implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization issues of JRuby objects.
 * JRuby classes do not support Java serialization.
 *
 * Note that the JRuby spout class is instanciated in the open method which is called after
 * deserialization at the worker and in the declareOutputFields & getComponentConfiguration
 * methods which are called once before serialization at topology creation.
 */
public class JRubySpout implements IRichSpout {
  private final String _realSpoutClassName;
  private final Map<String, String[]> _fields;
  private final String _bootstrap;

  // transient to avoid serialization
  private transient IRubyObject _ruby_spout;
  private transient Ruby __ruby__;

  /**
   * create a new JRubySpout
   *
   * @param baseClassPath the topology/project base JRuby class file path
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   * @param fields the output fields names
   */
  public JRubySpout(String baseClassPath, String realSpoutClassName, Map<String, String[]> fields) {
    _realSpoutClassName = realSpoutClassName;
    _fields = fields;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  @Override
  public void open(final Map conf, final TopologyContext context, final SpoutOutputCollector collector) {
    _ruby_spout = initialize_ruby_spout();
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    IRubyObject ruby_collector = JavaUtil.convertJavaToRuby(__ruby__, collector);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "open", ruby_conf, ruby_context, ruby_collector);
  }

  @Override
  public void close() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "close");
  }

  @Override
  public void activate() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "activate");
  }

  @Override
  public void deactivate() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "deactivate");
  }

  @Override
  public void nextTuple() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "next_tuple");
  }

  @Override
  public void ack(Object msgId) {
    IRubyObject ruby_msg_id = JavaUtil.convertJavaToRuby(__ruby__, msgId);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "ack", ruby_msg_id);
  }

  @Override
  public void fail(Object msgId) {
    IRubyObject ruby_msg_id = JavaUtil.convertJavaToRuby(__ruby__, msgId);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "fail", ruby_msg_id);
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time, before serialisation.
    // just create tmp spout instance to call declareOutputFields.

    if (_fields.size() > 0) {
      Iterator iterator = _fields.entrySet().iterator();
      while (iterator.hasNext()) {
        Map.Entry<String, String[]> field = (Map.Entry<String, String[]>)iterator.next();
        declarer.declareStream(field.getKey(), new Fields(field.getValue()));
        iterator.remove();
      }
    } else {
      IRubyObject ruby_spout = initialize_ruby_spout();
      IRubyObject ruby_declarer = JavaUtil.convertJavaToRuby(__ruby__, declarer);
      Helpers.invoke(__ruby__.getCurrentContext(), ruby_spout, "declare_output_fields", ruby_declarer);
    }
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time, before serialisation.
    // just create tmp spout instance to call getComponentConfiguration.

    IRubyObject ruby_spout = initialize_ruby_spout();
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), ruby_spout, "get_component_configuration");
    return (Map)ruby_result.toJava(Map.class);
  }

  private IRubyObject initialize_ruby_spout() {
    __ruby__ = Ruby.getGlobalRuntime();

    RubyModule ruby_class;
    try {
      ruby_class = __ruby__.getClassFromPath(_realSpoutClassName);
    }
    catch (RaiseException e) {
      // after deserialization we need to recreate ruby environment
      __ruby__.evalScriptlet(_bootstrap);
      ruby_class = __ruby__.getClassFromPath(_realSpoutClassName);
    }
    return Helpers.invoke(__ruby__.getCurrentContext(), ruby_class, "new");
  }
}
