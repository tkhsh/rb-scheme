module RbScheme
  class Box
    def initialize(val)
      @value = val
    end

    def set_box!(val)
      @value = val
    end

    def unbox
      @value
    end
  end
end
