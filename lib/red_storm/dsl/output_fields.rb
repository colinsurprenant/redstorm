module RedStorm
  module DSL
    module OutputFields

      def self.included(base)
        base.extend ClassMethods
      end

      def declare_output_fields(declarer)
        self.class.fields.each do |stream, fields|
          declarer.declareStream(stream, Fields.new(fields))
        end
      end

      def stream
        self.class.stream
      end

      module ClassMethods

        def output_fields(*fields)
          @output_fields ||= Hash.new([])
          fields.each do |field|
            case field
            when Hash
              field.each { |k, v| @output_fields[k.to_s] = v.kind_of?(Array) ? v.map(&:to_s) : [v.to_s] }
            else
              @output_fields['default'] |= field.kind_of?(Array) ? field.map(&:to_s) : [field.to_s]
            end
          end
        end

        def fields
          @output_fields ||= Hash.new([])
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

