require 'java'

module RedStorm
  module Loggable

    def self.log
      @log ||= Java::OrgSlf4j::LoggerFactory.get_logger(self.name)
    end

    def log
      self.class.log
    end

  end
end
