require 'red_storm'

module RedStorm
  module Examples
    class WordCountBolt < DSL::Bolt
      output_fields :word, :count
      on_init {@counts = Hash.new{|h, k| h[k] = 0}}

      # block declaration style using auto-emit (default)
      #
      on_receive do |tuple|
        word = tuple[0].to_s
        @counts[word] += 1

        [word, @counts[word]]
      end
    end
  end
end
