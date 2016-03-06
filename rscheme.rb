require "forwardable"

module RScheme
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

  class LTrue
    def self.type
      Type::TRUE
    end
  end

  class LFalse
    def self.type
      Type::FALSE
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

  class LLambda
    attr_accessor :params, :body, :env

    def initialize(params, body, env)
      @params = params
      @body = body
      @env = env
    end

    def type
      Type::LAMBDA
    end
  end

  module Symbol
    @@symbols = {}

    def intern(name)
      return @@symbols[name] if @@symbols.has_key?(name)

      sym = LSymbol.new(name)
      @@symbols[name] = sym
      sym
    end

  end

  module Helpers
    # Constructor
    def cons(car, cdr)
      LCell.new(car, cdr)
    end

    def acons(key, val, cdr)
      cons(cons(key, val), cdr)
    end

    def array_to_list(array)
      result = LNIL
      array.reverse_each do |e|
        result = cons(e, result)
      end
      result
    end
  end

  class Evaluator
    include Helpers

    def lookup_variable(var, env)
      env.each do |frame|
        frame.each do |bind|
          return bind.cdr if var.name == bind.car.name
        end
      end

      raise "Unbound variable - #{var.name}"
    end

    def map_eval(list, env)
      result_array = list.map { |e| eval(e, env) }
      array_to_list(result_array)
    end

    def progn(expr_list, env)
      expr_list.map { |expr| eval(expr, env) }.last
    end

    def extend_env(env, vars, vals)
      frame = LNIL
      vars.to_a.zip(vals.to_a) do |var, val|
        frame = acons(var, val, frame)
      end
      cons(frame, env)
    end

    def apply(fn, args, env)
      extended = extend_env(env, fn.params, args)
      progn(fn.body, extended)
    end

    def eval(obj, env)
      case obj.type
      when Type::INT,  Type::PRIMITIVE, Type::FUNCTION,
           Type::TRUE, Type::FALSE, Type::NIL
        obj
      when Type::SYMBOL
        lookup_variable(obj, env)
      when Type::CELL
        raise "Invalid application" unless obj.list?

        fst = eval(obj.car, env)
        case fst.type
        when Type::SYNTAX
          fst.syntax.call(obj.cdr, env)
        when Type::SUBROUTINE
          args = map_eval(obj.cdr, env)
          fst.subr.call(args, env)
        when Type::LAMBDA
          args = map_eval(obj.cdr, env)
          apply(fst, args, env)
        else
          raise "application - unexpected type #{fst.type}"
        end
      else
        raise "Unexpected type - #{obj.type}"
      end
    end

  end # Evaluator

  class Parser
    extend Forwardable
    include Helpers
    include Symbol

    EOF = nil

    def_delegator :@input, :getc

    def initialize(input)
      @input = input
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

    def read_hash
      c = getc
      case c
      when 't'
        LTrue
      when 'f'
        LFalse
      else
        raise "Unexpected hash literal #{c}"
      end
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
        when '#'
          return read_hash
        when symbol_rp
          return read_symbol(c)
        else
          raise "Unexpected character - #{c}"
        end
      end
    end

  end # Parser

  require "yaml"
  class Printer
    def print(obj)
      puts YAML.dump(obj)
    end
  end # Printer

  class Primitive
    extend Forwardable
    include Helpers
    include Symbol

    def_delegator :@evaluator, :eval

    def initialize
      @evaluator = Evaluator.new
    end

    def syntax_lambda
      lambda do |form, env|
        params = form.car
        body = form.cdr

        unless form.count > 1 && params.list? && body.list?
          raise "Malformed lambda"
        end

        params.each do |p|
          raise "lambda - parameters must be Symbol" unless p.type == Type::SYMBOL
        end

        LLambda.new(params, body, env)
      end
    end

    def syntax_if
      lambda do |form, env|
        raise "Malformed if" if form.count < 2

        cond = eval(form.car, env)
        if cond.type != Type::FALSE
          eval(form.cadr, env)
        else
          eval(form.caddr, env)
        end
      end
    end

    def arithmetic_proc(op)
      lambda do |args, env|
        args.each do |e|
          raise "#{op} supports only numbers" if e.type != Type::INT
        end
        fst = args.first
        rest = args.drop(1)
        val = rest.reduce(fst.value) { |res, n| yield(res, n.value) }
        LInt.new(val)
      end
    end

    def subr_plus
      arithmetic_proc("+") { |res, n| res + n }
    end

    def subr_minus
      arithmetic_proc("-") { |res, n| res - n }
    end

    def subr_mul
      arithmetic_proc("*") { |res, n| res * n }
    end

    def subr_div
      arithmetic_proc("/") { |res, n| res / n }
    end

    def add_primitive!(env)
      add_syntax!(env, :lambda, syntax_lambda)
      add_syntax!(env, :if, syntax_if)
      add_subrutine!(env, :+, subr_plus)
      add_subrutine!(env, :-, subr_minus)
      add_subrutine!(env, :*, subr_mul)
      add_subrutine!(env, :/, subr_div)
      # todo ...
    end

    def add_syntax!(env, name, p)
      env.car = acons(intern(name), LSyntax.new(name, p), env.car)
    end

    def add_subrutine!(env, name, p)
      env.car = acons(intern(name), LSubroutine.new(name, p), env.car)
    end

  end # Primitive

  class Executer
    extend Forwardable
    include Helpers

    def_delegator :@parser, :read_expr
    def_delegator :@primitive, :add_primitive!
    def_delegator :@evaluator, :eval
    def_delegator :@printer, :print

    def init_env
      cons(LNIL, LNIL)
    end

    def self.run
      new.exec
    end

    def initialize(source = STDIN)
      set_source!(source)
      @primitive = Primitive.new
      @evaluator = Evaluator.new
      @printer = Printer.new
    end

    def set_source!(source)
      @parser = Parser.new(source)
    end

    def exec
      env = init_env
      add_primitive!(env)

      loop do
        expr = read_expr
        return if expr.nil?
        print(eval(expr, env))
      end
    end
  end # Executer
end

# RScheme::Executer.run
