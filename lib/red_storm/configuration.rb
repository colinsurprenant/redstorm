module RedStorm
  module Configuration
    extend self

    @topology_class = nil

    def topology_class=(clazz)
      @topology_class = clazz
    end

    def topology_class
      @topology_class
    end

  end
end
