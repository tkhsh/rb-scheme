module RbScheme
  module Type
    INT = 1
    CELL = 2
    SYMBOL = 3
    DOT = 4
    CLOSEPAREN = 5
    NIL = 6
    TRUE = 7
    FALSE = 8
    PRIMITIVE = 9
    FUNCTION = 10
    SYNTAX = 11
    SUBROUTINE = 12
    LAMBDA = 13
    MACRO = 14

    def self.included(base)
      # Example
      #   base.name => RbScheme::LInt
      #   type_name => INT
      type_name = base.name.split('::').last[1..-1].upcase

      base.class_eval %Q{
        def self.type
          #{const_get(type_name)}
        end

        def type
          self.class.type
        end
      }
    end
  end # Type

  class LInt
    include Type

    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  class LCell
    include Type
    include Enumerable

    attr_accessor :car, :cdr

    def initialize(car = nil, cdr = nil)
      @car = car
      @cdr = cdr
    end

    def each
      list = self
      until list.type == Type::NIL
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

    def list?
      cdr = @cdr
      loop do
        return true if cdr.type == Type::NIL
        return false if cdr.type != Type::CELL
        cdr = cdr.cdr
      end
    end
  end

  class LSymbol
    include Type

    attr_accessor :name

    def initialize(name)
      @name = name
    end
  end

  class LDot
    include Type
  end

  class LCloseParen
    include Type
  end

  class LNil
    include Type
  end

  class LTrue
    include Type
  end

  class LFalse
    include Type
  end

  class LSyntax
    include Type

    attr_accessor :name, :syntax

    def initialize(name, syntax)
      @name = name
      @syntax = syntax
    end
  end

  class LSubroutine
    include Type

    attr_accessor :name, :subr

    def initialize(name, subr)
      @name = name
      @subr = subr
    end
  end

  class LLambda
    include Type

    attr_accessor :params, :body, :env

    def initialize(params, body, env)
      @params = params
      @body = body
      @env = env
    end
  end

  class LMacro
    include Type

    attr_accessor :name, :form

    def initialize(name, form)
      @name = name
      @form = form
    end
  end
end # RbScheme

