class WordCountBolt < RedStorm::SimpleBolt
  output_fields :word, :count

  on_init {@counts = Hash.new{|h, k| h[k] = 0}}

  on_tuple do |tuple|
    word = tuple.getString(0)
    @counts[word] += 1

    [word, @counts[word]]
  end
end

# below is the same bolt but passing a method name to on_tuple

# class WordCountBolt < RedStorm::SimpleBolt
#   output_fields :word, :count
#   on_init {@counts = Hash.new{|h, k| h[k] = 0}}
#   on_tuple :count_word
#
#   def count_word(tuple)
#     word = tuple.getString(0)
#     @counts[word] += 1
#
#     [word, @counts[word]]
#   end
# end
