require 'singleton'

module RbScheme
  class LInt
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(another)
      return false unless another.is_a? LInt
      value == another.value
    end
  end

  class LCell
    include Enumerable

    attr_accessor :car, :cdr

    def initialize(car = nil, cdr = nil)
      @car = car
      @cdr = cdr
    end

    def each
      list = self
      until LNil === list
        yield(list.car)
        list = list.cdr
      end
    end

    def cadr
      @cdr.car
    end

    def caddr
      @cdr.cdr.car
    end

    def cadddr
      @cdr.cdr.cdr.car
    end

    def list?
      cdr = @cdr
      loop do
        return true if LNil === cdr
        return false unless LCell === cdr
        cdr = cdr.cdr
      end
    end

    def ==(another)
      l1 = self
      l2 = another
      loop do
        if l1.is_a?(LCell) && l2.is_a?(LCell)
          return false unless l1.car == l2.car
          l1 = l1.cdr
          l2 = l2.cdr
        elsif !l1.is_a?(LCell) && !l2.is_a?(LCell)
          return l1 == l2
        else
          return false
        end
      end
    end

  end

  class LSymbol
    attr_accessor :name

    def initialize(name)
      @name = name
    end
  end

  class LDot
    include Singleton
  end

  class LCloseParen
    include Singleton
  end

  class LNil
    include Singleton
    include Enumerable

    def each; end
    def list?; true; end
  end

  class LTrue
    include Singleton
  end

  class LFalse
    include Singleton
  end

end # RbScheme

