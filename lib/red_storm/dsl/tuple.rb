java_import 'backtype.storm.tuple.Tuple'
java_import 'backtype.storm.tuple.TupleImpl'

module RedStorm
  module DSL
    class TupleError < StandardError; end
  end
end

class TupleImpl

  def value(i)
    case i
    when Fixnum
      getValue(i)
    when String
      getValueByField(i)
    when Symbol
      getValueByField(i.to_s)
    else
      raise(RedStorm::DSL::TupleError, "unsupported tuple index class=#{i.class.to_s} for #{i.inspect}")
    end
  end
  alias_method :[], :value

  alias_method :values, :getValues # wire directly to avoid method missing indirection

  def field_index(field)
    fieldIndex(field.to_s)
  end

  # Because of https://jira.codehaus.org/browse/JRUBY-6643
  java_signature 'boolean isContains(Object)'
  def contains?(field)
    contains(field.to_s)
  end

end
