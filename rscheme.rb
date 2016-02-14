module RScheme

  module LispObject
    @@symbols = {}

    module Type
      INT = 1
      CELL = 2
      SYMBOL = 3
      DOT = 4
      CLOSEPAREN = 5
      NIL = 6
      TRUE = 7
      PRIMITIVE = 8
      FUNCTION = 9
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
      attr_accessor :name

      def initialize(name)
        @name = name
      end

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

    def intern(name)
      return @@symbols[name] if @@symbols.has_key?(name)

      sym = LSymbol.new(name)
      @@symbols[name] = sym
      sym
    end

    # Constructor
    def cons(car, cdr)
      LCell.new(car, cdr)
    end

  end # LispObject


  class Parser
    include LispObject

    EOF = nil

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

    def skip_line
      loop do
        c = getc
        case c
        when EOF, '\n'
          return
        when '\r'
          getc if '\n' == peek
          return
        end
      end
    end

    def read_list
      acc = LNIL
      loop do
        obj = read_expr
        raise "read_list: Unclosed parenthesis" if obj.nil?

        case obj.type
        when Type::CLOSEPAREN
          return reverse_list(acc)
        when Type::DOT
          last = read_expr
          close = read_expr
          if close.nil? || close.type != Type::CLOSEPAREN
            raise "read_list: Unclosed parenthesis"
          end
          if acc.type == Type::NIL
            raise "read_list: dotted list must have car"
          end
          result = cons(acc.car, last)
          cdr = acc.cdr
          until cdr.type == Type::NIL
            result = cons(cdr.car, result)
            cdr = cdr.cdr
          end
          return result
        else
          acc = cons(obj, acc)
        end
      end
    end

    def read_quote
      sym = intern(:quote)
      cons(sym, read_expr)
    end

    def read_number(value)
      result = value
      while /\d/ === peek
        result = result * 10 + getc.to_i
      end
      result
    end

    def read_symbol(first_char)
      result = first_char
      while symbol_rp === peek
        result += getc
      end
      intern(result.to_sym)
    end

    def negative_number_pred
      Proc.new {|c| '-' == c && /\d/ === peek}
    end

    def symbol_rp
      allowed = '~!@$%^&*-_=+:/?<>'
      Regexp.new("[A-Za-z#{Regexp.escape(allowed)}]")
    end

    def read_expr
      loop do
        c = getc
        case c
        when /\s/
          next
        when EOF
          return nil
        when ';'
          skip_line
          next
        when '('
          return read_list
        when ')'
          return LCloseParen
        when '.'
          return LDot
        when '\''
          return read_quote
        when /\d/
          return LInt.new(read_number(c.to_i))
        when negative_number_pred
          return LInt.new(-read_number(c.to_i))
        when symbol_rp
          return read_symbol(c)
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
