package redstorm.storm.jruby;

import backtype.storm.transactional.ICommitter;

public class JRubyBatchCommitterBolt extends JRubyBatchBolt implements ICommitter {
  public JRubyBatchCommitterBolt(String baseClassPath, String realBoltClassName) {
    super(baseClassPath, realBoltClassName);
  }
}