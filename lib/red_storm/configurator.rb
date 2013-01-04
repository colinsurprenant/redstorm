module RedStorm

  class Configurator
    attr_reader :config

    def initialize(defaults = {})
      @config = Backtype::Config.new
      defaults.each{|attribute, value| @config.put(attribute.to_s, value)}
    end

    def set(attribute, value)
      @config.put(attribute.to_s, value)
    end

    def method_missing(sym, *args)
      config_method = "set#{self.class.camel_case(sym)}"
      @config.send(config_method, *args)
    end

    private

    def self.camel_case(s)
      s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
  end
end