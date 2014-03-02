package redstorm.storm.jruby;

import backtype.storm.task.OutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.IRichBolt;
import backtype.storm.topology.OutputFieldsDeclarer;
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
 * the JRubyBolt class is a proxy class to the actual bolt implementation in JRuby.
 * this proxy is required to bypass the serialization/deserialization issues of JRuby objects.
 * JRuby classes do not support Java serialization.
 *
 * Note that the JRuby bolt class is instanciated in the prepare method which is called after
 * deserialization at the worker and in the declareOutputFields & getComponentConfiguration
 * methods which are called once before serialization at topology creation.
 */
public class JRubyBolt implements IRichBolt {
  private final String _realBoltClassName;
  private final String[] _fields;
  private final String _bootstrap;

  // transient to avoid serialization
  private transient IRubyObject _ruby_bolt;
  private transient Ruby __ruby__;

  /**
   * create a new JRubyBolt
   *
   * @param baseClassPath the topology/project base JRuby class file path
   * @param realBoltClassName the fully qualified JRuby bolt implementation class name
   * @param fields the output fields names
   */
  public JRubyBolt(String baseClassPath, String realBoltClassName, String[] fields) {
    _realBoltClassName = realBoltClassName;
    _fields = fields;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  @Override
  public void prepare(final Map conf, final TopologyContext context, final OutputCollector collector) {
    _ruby_bolt = initialize_ruby_bolt();
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    IRubyObject ruby_collector = JavaUtil.convertJavaToRuby(__ruby__, collector);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_bolt, "prepare", ruby_conf, ruby_context, ruby_collector);
  }

  @Override
  public void execute(Tuple input) {
    IRubyObject ruby_input = JavaUtil.convertJavaToRuby(__ruby__, input);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_bolt, "execute", ruby_input);
  }

  @Override
  public void cleanup() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_bolt, "cleanup");
  }

  @Override
  public void declareOutputFields(OutputFieldsDeclarer declarer) {
    // declareOutputFields is executed in the topology creation time, before serialisation.
    // just create tmp bolt instance to call declareOutputFields.

    if (_fields.length > 0) {
      declarer.declare(new Fields(_fields));
    } else {
      IRubyObject ruby_bolt = initialize_ruby_bolt();
      IRubyObject ruby_declarer = JavaUtil.convertJavaToRuby(__ruby__, declarer);
      Helpers.invoke(__ruby__.getCurrentContext(), ruby_bolt, "declare_output_fields", ruby_declarer);
    }
  }

  @Override
  public Map<String, Object> getComponentConfiguration() {
    // getComponentConfiguration is executed in the topology creation time, before serialisation.
    // just create tmp bolt instance to call getComponentConfiguration.

    IRubyObject ruby_bolt = initialize_ruby_bolt();
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), ruby_bolt, "get_component_configuration");
    return (Map)ruby_result.toJava(Map.class);
  }

  private IRubyObject initialize_ruby_bolt() {
    __ruby__ = Ruby.getGlobalRuntime();

    RubyModule ruby_class;
    try {
      ruby_class = __ruby__.getClassFromPath(_realBoltClassName);
    }
    catch (RaiseException e) {
      // after deserialization we need to recreate ruby environment
      __ruby__.evalScriptlet(_bootstrap);
      ruby_class = __ruby__.getClassFromPath(_realBoltClassName);
    }
    return Helpers.invoke(__ruby__.getCurrentContext(), ruby_class, "new");
  }
}
