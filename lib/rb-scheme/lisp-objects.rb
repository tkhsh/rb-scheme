require 'singleton'

module RbScheme
  class LInt
    attr_accessor :value

    def initialize(value)
      @value = value
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

  class LSyntax
    attr_accessor :name, :syntax

    def initialize(name, syntax)
      @name = name
      @syntax = syntax
    end
  end

  class LSubroutine
    attr_accessor :name, :subr

    def initialize(name, subr)
      @name = name
      @subr = subr
    end
  end

  class LLambda
    attr_accessor :params, :body, :env

    def initialize(params, body, env)
      @params = params
      @body = body
      @env = env
    end
  end

  class LMacro
    attr_accessor :name, :form

    def initialize(name, form)
      @name = name
      @form = form
    end
  end
end # RbScheme

