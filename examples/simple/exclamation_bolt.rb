class ExclamationBolt < RedStorm::SimpleBolt
  output_fields :word
  on_tuple(:ack => true, :anchor => true) {|tuple| tuple.getString(0) + "!!!"}
end
