package redstorm.storm.jruby;

import backtype.storm.tuple.Fields;
import backtype.storm.task.TopologyContext;
import storm.trident.operation.TridentCollector;
import storm.trident.spout.IBatchSpout;
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
public class JRubyBatchSpout implements IBatchSpout {
  private final String _realSpoutClassName;
  private final String[] _fields;
  private final String _bootstrap;

  // transient to avoid serialization
  private transient IRubyObject _ruby_spout;
  private transient Ruby __ruby__;

  /**
   * create a new JRubyBatchSpout
   *
   * @param baseClassPath the topology/project base JRuby class file path
   * @param realSpoutClassName the fully qualified JRuby spout implementation class name
   * @param fields the output fields names
   */
  public JRubyBatchSpout(String baseClassPath, String realSpoutClassName) {
    _realSpoutClassName = realSpoutClassName;
    _fields = null;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  /* constructor for compatibility with JRubySpout signature */
  public JRubyBatchSpout(String baseClassPath, String realSpoutClassName, String[] fields) {
    _realSpoutClassName = realSpoutClassName;
    _fields = fields;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  @Override
  public void open(final Map conf, final TopologyContext context) {
    // // create instance of the jruby proxy class here, after deserialization in the workers.
    // _proxySpout = newProxySpout(_baseClassPath, _realSpoutClassName);
    // _proxySpout.open(conf, context);


    _ruby_spout = initialize_ruby_spout();
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "open", ruby_conf, ruby_context);
  }

  @Override
  public void emitBatch(long batchId, TridentCollector collector) {
    // _proxySpout.emitBatch(batchId, collector);

    IRubyObject ruby_batch_id = JavaUtil.convertJavaToRuby(__ruby__, batchId);
    IRubyObject ruby_collector = JavaUtil.convertJavaToRuby(__ruby__, collector);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "emit_batch", ruby_batch_id, ruby_collector);
  }

  @Override
  public void close() {
    // _proxySpout.close();

    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "close");
  }

  @Override
  public void ack(long batchId) {
    // _proxySpout.ack(batchId);

    IRubyObject ruby_batch_id = JavaUtil.convertJavaToRuby(__ruby__, batchId);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "ack", ruby_batch_id);
  }

  @Override
  public Fields getOutputFields() {
    IRubyObject ruby_spout = initialize_ruby_spout();
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), ruby_spout, "get_output_fields");
    return (Fields)ruby_result.toJava(Fields.class);
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
