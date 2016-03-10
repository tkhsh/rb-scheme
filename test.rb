require 'minitest/autorun'
require 'stringio'
require './rscheme'

class TestParser < Minitest::Test
  include RScheme

  def test_read_expr
    # integer
    StringIO.open("1 -1 10") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.value
      assert_equal Type::INT, expr1.type
      expr2 = parser.read_expr
      assert_equal -1, expr2.value
      assert_equal Type::INT, expr2.type
      expr3 = parser.read_expr
      assert_equal 10, expr3.value
      assert_equal Type::INT, expr3.type
    end

    # symbol
    StringIO.open("a bc") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal "a", expr1.name
      assert_equal Type::SYMBOL, expr1.type
      expr2 = parser.read_expr
      assert_equal "bc", expr2.name
      assert_equal Type::SYMBOL, expr2.type
    end

    # quote
    StringIO.open("'a '(a b c)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal "quote", expr1.car.name
      assert expr1.list?
      expr2 = parser.read_expr
      assert_equal "quote", expr2.car.name
      assert expr2.list?
    end

    # list
    StringIO.open("(1 2 3) (a) ()") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.car.value
      assert_equal 3, expr1.cdr.cdr.car.value
      assert_equal Type::NIL, expr1.cdr.cdr.cdr.type
      expr2 = parser.read_expr
      assert_equal "a", expr2.car.name
      assert_equal Type::NIL, expr2.cdr.type
      expr3 = parser.read_expr
      assert_equal Type::NIL, expr3.type
    end

    # dotted list
    StringIO.open("(1 . 2) (f 1 . 3)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.value
      expr2 = parser.read_expr
      assert_equal "f", expr2.car.name
      assert_equal 1, expr2.cdr.car.value
      assert_equal 3, expr2.cdr.cdr.value
    end

    # hash
    StringIO.open("#t #f") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal Type::TRUE, expr1.type
      expr2 = parser.read_expr
      assert_equal Type::FALSE, expr2.type
    end
  end
end

class TestExecuter < Minitest::Test
  include RScheme

  def setup
    @executer = Executer.new
    @env = @executer.init_env
    @executer.add_primitive!(@env)
  end

  def eval_next(env)
    expr = @executer.read_expr
    raise if expr.nil?
    @executer.eval(expr, env)
  end

  def test_eval
    # subr_plus
    StringIO.open("(+ 1 2 (+ 3 4))") do |strio|
      @executer.set_source!(strio)

      result = eval_next(@env)
      assert_equal Type::INT, result.type
      assert_equal 10, result.value
    end

    # syntax_if
    StringIO.open("(if #t 1 2) (if #f 1 2)") do |strio|
      @executer.set_source!(strio)

      result1 = eval_next(@env)
      assert_equal Type::INT, result1.type
      assert_equal 1, result1.value
      result2 = eval_next(@env)
      assert_equal Type::INT, result2.type
      assert_equal 2, result2.value
    end

    # syntax_lambda
    StringIO.open("((lambda (x y) (* x y 2)) 5 7)") do |strio|
      @executer.set_source!(strio)

      result = eval_next(@env)
      assert_equal Type::INT, result.type
      assert_equal 70, result.value
    end

    # syntax_define
    StringIO.open("(define a (+ 1 2)) a") do |strio|
      @executer.set_source!(strio)

      eval_next(@env)
      result = eval_next(@env)
      assert_equal Type::INT, result.type
      assert_equal 3, result.value
    end

    # syntax_macro
    macro_exprs = <<-EXPRS
    (define-macro my-not
      (lambda (cond) (list 'if cond #f #t)))
    (my-not #t)
    EXPRS
    StringIO.open(macro_exprs) do |strio|
      @executer.set_source!(strio)

      eval_next(@env)
      result = eval_next(@env)
      assert_equal Type::FALSE, result.type
    end

    # syntax_set!
    set_exprs = <<-EXPRS
    (define x 10)
    x
    (set! x 20)
    x
    EXPRS
    StringIO.open(set_exprs) do |strio|
      @executer.set_source!(strio)

      eval_next(@env)
      result1 = eval_next(@env)
      assert_equal 10, result1.value
      result2 = eval_next(@env)
      assert_equal 20, result2.value
    end
  end
end
