require 'java'

module RedStorm
  module Loggable

    def self.log
      @log ||= Java::OrgApacheLog4j::Logger.getLogger(self.name)
    end

    def log
      self.class.log
    end

  end
end
