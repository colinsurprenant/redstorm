package redstorm.storm.jruby;

import storm.trident.tuple.TridentTuple;
import storm.trident.operation.TridentCollector;
import java.util.Map;
import storm.trident.operation.TridentOperationContext;
import storm.trident.operation.Function;

public class JRubyProxyFunction implements Function {
  Function _proxy;
  String _realClassName;
  String _baseClassPath;
  String[] _fields;

  public JRubyProxyFunction(final String baseClassPath, final String realClassName, final String[] fields) {
    _baseClassPath = baseClassPath;
    _realClassName = realClassName;
    _fields = fields;
  }


  @Override
  public void execute(final TridentTuple _tridentTuple, final TridentCollector _tridentCollector) {
    
    if(_proxy == null) {
      _proxy = newProxy(_baseClassPath, _realClassName);
    }
    _proxy.execute(_tridentTuple, _tridentCollector);
    
  }

  @Override
  public void cleanup() {
    
    _proxy.cleanup();
    
  }

  @Override
  public void prepare(final Map _map, final TridentOperationContext _tridentOperationContext) {
    
    if(_proxy == null) {
      _proxy = newProxy(_baseClassPath, _realClassName);
    }
    _proxy.prepare(_map, _tridentOperationContext);
    
  }


  private static Function newProxy(final String baseClassPath, final String realClassName) {
    try {
      redstorm.proxy.ProxyFunction proxy = new redstorm.proxy.ProxyFunction(baseClassPath, realClassName);
      return proxy;
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
