package redstorm.storm.jruby;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.base.BaseTransactionalSpout;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.transactional.ITransactionalSpout;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Fields;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;

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
  private final String _realSpoutClassName;
  private final String[] _fields;
  private final String _bootstrap;

  // transient to avoid serialization
  protected transient IRubyObject _ruby_spout;
  protected transient Ruby __ruby__;

  /**
   * create a new JRubySpout
   *
   * @param baseClassPath the topology/project base JRuby class file path
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   * @param fields the output fields names
   */
  public JRubyTransactionalSpout(String baseClassPath, String realSpoutClassName, String[] fields) {
    _realSpoutClassName = realSpoutClassName;
    _fields = fields;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  @Override
  public ITransactionalSpout.Coordinator getCoordinator(Map conf, TopologyContext context) {
    if (_ruby_spout == null) {
      IRubyObject _ruby_spout = initialize_ruby_spout();
    }
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "get_coordinator", ruby_conf, ruby_context);
    return (ITransactionalSpout.Coordinator)ruby_result.toJava(ITransactionalSpout.Coordinator.class);
  }

  @Override
  public ITransactionalSpout.Emitter getEmitter(Map conf, TopologyContext context) {
    if (_ruby_spout == null) {
      IRubyObject _ruby_spout = initialize_ruby_spout();
    }
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "get_emitter", ruby_conf, ruby_context);
    return (ITransactionalSpout.Emitter)ruby_result.toJava(ITransactionalSpout.Emitter.class);
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time, before serialisation.
    // just create tmp spout instance to call declareOutputFields.

    if (_fields.length > 0) {
      declarer.declare(new Fields(_fields));
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

  protected IRubyObject initialize_ruby_spout() {
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
