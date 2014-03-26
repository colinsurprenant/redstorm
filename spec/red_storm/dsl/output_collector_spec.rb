require 'spec_helper'
require 'red_storm/dsl/output_collector'

describe OutputCollector do
  describe '#instance methods' do
    subject { described_class.new('foo') }

    # We should have an alias for #emit_tuple
    it { should respond_to :emit_tuple }

    # We should have an alias for #emit_anchor_tuple
    it { should respond_to :emit_anchor_tuple }
  end
end
