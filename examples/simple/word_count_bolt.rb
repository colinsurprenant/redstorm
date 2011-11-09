class WordCountBolt < RedStorm::SimpleBolt
  output_fields :word, :count

  on_tuple do |tuple|
    word = tuple.getString(0)
    @counts[word] += 1

    [word, @counts[word]]
  end

  def initialize
    @counts = Hash.new{|h, k| h[k] = 0}
  end
end


# class WordCountBolt < RedStorm::SimpleBolt

#   output_fields :word, :count
#   on_tuple :count_word, :ack => true, :anchor => true

#   def count_word(tuple)
#     word = tuple.getString(0)
#     @counts[word] += 1

#     [word, @counts[word]]
#   end

#   def initialize
#     @counts = Hash.new{|h, k| h[k] = 0}
#   end
# end
