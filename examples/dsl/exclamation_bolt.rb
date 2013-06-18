require 'red_storm'

module RedStorm
  module Examples
    class ExclamationBolt < DSL::Bolt
      output_fields :word
      on_receive(:ack => true, :anchor => true) {|tuple| tuple[0] + "!!!"} # tuple[:word] or tuple["word"] are also valid
    end
  end
end
