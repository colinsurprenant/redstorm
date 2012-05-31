module RedStorm
  module Loggable

    def self.log
      @log ||= Logger.getLogger(self.name)
    end

    def log
      self.class.log
    end

  end
end
