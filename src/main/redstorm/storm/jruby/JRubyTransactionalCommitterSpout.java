package redstorm.storm.jruby;

import backtype.storm.transactional.ICommitterTransactionalSpout;
import backtype.storm.transactional.ITransactionalSpout;
import backtype.storm.task.TopologyContext;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;

public class JRubyTransactionalCommitterSpout extends JRubyTransactionalSpout implements ICommitterTransactionalSpout {

  public JRubyTransactionalCommitterSpout(String baseClassPath, String realSpoutClassName, String[] fields) {
    super(baseClassPath, realSpoutClassName, fields);
  }

  @Override
  public ICommitterTransactionalSpout.Emitter getEmitter(Map conf, TopologyContext context) {
    if (_ruby_spout == null) {
      IRubyObject _ruby_spout = initialize_ruby_spout();
    }
    IRubyObject ruby_conf = JavaUtil.convertJavaToRuby(__ruby__, conf);
    IRubyObject ruby_context = JavaUtil.convertJavaToRuby(__ruby__, context);
    IRubyObject ruby_result = Helpers.invoke(__ruby__.getCurrentContext(), _ruby_spout, "get_emitter", ruby_conf, ruby_context);
    return (ICommitterTransactionalSpout.Emitter)ruby_result.toJava(ICommitterTransactionalSpout.Emitter.class);
  }
}