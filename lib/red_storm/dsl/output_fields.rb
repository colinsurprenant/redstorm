
module RedStorm
  module DSL
    module OutputFields

      def self.included(base)
        base.extend ClassMethods
      end

      def declare_output_fields(declarer)
        default_fields = []
        self.class.fields.each do |field|
          if field.kind_of? Hash
            field.each do |stream, fields|
              declarer.declareStream(stream, Fields.new(fields))
            end
          else
            default_fields << field
          end
        end

        declarer.declare(Fields.new(default_fields.flatten)) unless default_fields.empty?
      end

      def stream
        self.class.stream
      end

      module ClassMethods
        def output_fields(*fields)
          @fields ||= []
          fields.each do |field|
            if field.kind_of? Hash
              @fields << Hash[
                field.map { |k, v| [k.to_s, v.kind_of?(Array) ? v.map(&:to_s) : v.to_s] }
              ]
            else
              @fields << field.to_s
            end
          end
        end

        def fields
          @fields ||= []
        end

        def stream?
          self.receive_options[:stream] && !self.receive_options[:stream].empty?
        end

        def stream
          self.receive_options[:stream]
        end
      end
    end
  end
end

