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
      SYNTAX = 10
      SUBROUTINE = 11
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
      include Enumerable

      attr_accessor :car, :cdr

      def initialize(car = nil, cdr = nil)
        @car = car
        @cdr = cdr
      end

      def type
        Type::CELL
      end

      def each
        list = self
        until list.type == Type::NIL
          yield(list.car)
          list = list.cdr
        end
      end

      def cdar
        @cdr.car
      end

      def cddar
        @cdr.cdr.car
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

    class LSyntax
      attr_accessor :name, :syntax

      def initialize(name, syntax)
        @name = name
        @syntax = syntax
      end

      def type
        Type::SYNTAX
      end
    end

    class LSubroutine
      attr_accessor :name, :subr

      def initialize(name, subr)
        @name = name
        @subr = subr
      end

      def type
        Type::SUBROUTINE
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

    def acons(key, val, cdr)
      cons(cons(key, val), cdr)
    end

    # Environment
    def init_env
      cons(nil, nil)
    end

    def lookup_variable(var, env)
      env.each do |frame|
        frame.each do |bind|
          return bind.cdr if var.name == bind.car.name
        end
      end

      raise "Unbound variable - #{var.name}"
    end

    def syntax_if
      lambda do |form, env|
        raise "Malformed if" if form.count < 2

        cond = eval(form.car, env)
        if cond.type != Type::NIL
          eval(form.cdar, env)
        else
          eval(form.cddar, env)
        end
      end
    end

    def subr_plus
      lambda do |args, env|
        args.reduce(0) do |sum, a|
          obj = eval(env, a)
          raise "+ supports only numbers" if obj.type != Type::INT

          sum + obj.value
        end
      end
    end

    def add_primitive!(env)
      add_syntax!(env, :if, syntax_if)
      add_subrutine!(env, :+, subr_plus)
      # todo ...
    end

    def add_syntax!(env, name, p)
      env.car = acons(intern(name), LSyntax.new(name, p), env.car)
    end

    def add_subrutine!(env, name, p)
      env.car = acons(intern(name), LSubroutine.new(name, p), env.car)
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
      list.reduce(LNIL) { |res, e| cons(e, res) }
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

          return acc.reduce(last) { |res, e| cons(e, res) }
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
          raise "Unexpected character - #{c}"
        end
      end
    end

  end # Parser

  class Evaluator
    include LispObject

    def eval(obj, env)
      case obj.type
      when Type::INT,  Type::PRIMITIVE, Type::FUNCTION,
           Type::TRUE, Type::NIL
        obj
      when Type::SYMBOL
        lookup_variable(obj, env)
      when Type::CELL
        raise NotImplementedError, "Cell"
      else
        raise "Unexpected type - #{obj.type}"
      end
    end

  end # Evaluator

  class Executer
    def self.run
      new.exec
    end

    def exec
      expr = Parser.new(STDIN).read_expr
    end
  end # Executer
end

# RScheme::Executer.run
