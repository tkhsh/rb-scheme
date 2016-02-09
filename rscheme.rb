module RScheme

  module LispObject

    module Type
      INT = 1
      CELL = 2
      SYMBOL = 3
      DOT = 4
      CLOSEPAREN = 5
      NIL = 6
    end

    class LInt
      attr_accessor :value

      def initialize(value)
        @value = value
      end

      def type
        Type::INT
      end
    end

    class LCell
      attr_accessor :car, :cdr

      def initialize(car = nil, cdr = nil)
        @car = car
        @cdr = cdr
      end

      def type
        Type::CELL
      end
    end

    class LSymbol
      attr_accessor :sym

      def type
        Type::SYMBOL
      end
    end

    class LDot
      def self.type
        Type::DOT
      end
    end

    class LCloseParen
      def self.type
        Type::CLOSEPAREN
      end
    end

    class LNIL
      def self.type
        Type::NIL
      end
    end

    # Constructor
    def cons(car, cdr)
      LCell.new(car, cdr)
    end

    def make_int(value)
      LInt.new(value)
    end

    end
  end # LispObject


  class Parser
    include LispObject

    def initialize(input)
      @input = input
    end

    def getc
      @input.getc
    end

    def peek
      c = getc
      @input.ungetc(c)
      c
    end

    def reverse_list(list)
      return LNIL if list.type == Type::NIL

      acc = cons(list.car, LNIL)
      cdr = list.cdr
      until cdr.type == Type::NIL
        acc = cons(cdr.car, acc)
        cdr = cdr.cdr
      end

      acc
    end

    def read_list
      acc = LNIL
      loop do
        obj = read_expr
        raise "error - read_list" if obj.nil?

        case obj.type
        when Type::CLOSEPAREN
          return reverse_list(acc)
        when Type::DOT
          # todo
          raise "error - no dot support"
        else
          acc = cons(obj, acc)
        end
      end
    end

    def read_number(value)
      result = value
      while /\d/ === peek
        result = result * 10 + getc.to_i
      end
      result
    end

    def negative_number_p?
      Proc.new {|c| '-' == c && /\d/ === peek}
    end

    def read_expr
      loop do
        c = getc
        case c
        when /\s/
          next
        when nil #EOF
          return nil
        # when ';'
        #   skip_line
        #   next
        when '('
          return read_list
        when ')'
          return LCloseParen
        when '.'
          return LDot
        # when '\''
        #   return read_quote
        when /\d/
          return make_int(read_number(c.to_i))
        when negative_number_p?
          return make_int(-read_number(c.to_i))
        # when symbol?
        #   return read_symbol
        else
          raise "error - read_expr"
        end
      end
    end

  end # Parser

  class Executer
    def self.run
      new.exec
    end

    def exec
      expr = Parser.new(STDIN).read_expr
    end
  end # Executer
end

RScheme::Executer.run
