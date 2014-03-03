package redstorm.storm.jruby;

import storm.trident.tuple.TridentTuple;
import storm.trident.operation.TridentCollector;
import java.util.Map;
import storm.trident.operation.TridentOperationContext;
import storm.trident.operation.Function;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;

public class JRubyTridentFunction implements Function {
  private final String _realClassName;
  private final String _bootstrap;

  // transient to avoid serialization
  private transient IRubyObject _ruby_function;
  private transient Ruby __ruby__;

  public JRubyTridentFunction(final String baseClassPath, final String realClassName) {
    _realClassName = realClassName;
    _bootstrap = "require '" + baseClassPath + "'";
  }

  @Override
  public void execute(final TridentTuple tuple, final TridentCollector collector) {
    IRubyObject ruby_tuple = JavaUtil.convertJavaToRuby(__ruby__, tuple);
    IRubyObject ruby_collector = JavaUtil.convertJavaToRuby(__ruby__, collector);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_function, "execute", ruby_tuple, ruby_collector);
  }

  @Override
  public void cleanup() {
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_function, "cleanup");
  }

  @Override
  public void prepare(final Map conf, final TridentOperationContext context) {
    if(_ruby_function == null) {
      _ruby_function = initialize_ruby_function();
    }
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    Helpers.invoke(__ruby__.getCurrentContext(), _ruby_function, "prepare", ruby_conf, ruby_context);
  }

  private IRubyObject initialize_ruby_function() {
    __ruby__ = Ruby.getGlobalRuntime();

    RubyModule ruby_class;
    try {
      ruby_class = __ruby__.getClassFromPath(_realClassName);
    }
    catch (RaiseException e) {
      // after deserialization we need to recreate ruby environment
      __ruby__.evalScriptlet(_bootstrap);
      ruby_class = __ruby__.getClassFromPath(_realClassName);
    }
    return Helpers.invoke(__ruby__.getCurrentContext(), ruby_class, "new");
  }
}
