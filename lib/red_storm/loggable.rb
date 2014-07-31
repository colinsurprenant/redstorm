require 'java'

module RedStorm
  module Loggable
    def self.included(clazz)
      clazz.send(:extend, ClassMethods)
      clazz.send(:include, InstanceMethods)
    end

    module ClassMethods
      def log
        @log ||= Java::OrgSlf4j::LoggerFactory.get_logger(self.name.gsub(/::/, '.'))
      end
    end

    module InstanceMethods
      def log
        self.class.log
      end
    end
  end
end
