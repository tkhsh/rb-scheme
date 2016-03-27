require 'minitest/autorun'
require 'stringio'
require 'rb-scheme'

class TestParser < Minitest::Test
  include RbScheme

  def test_read_expr
    # integer
    StringIO.open("1 -1 10") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.value
      assert_instance_of LInt, expr1
      expr2 = parser.read_expr
      assert_equal -1, expr2.value
      assert_instance_of LInt, expr2
      expr3 = parser.read_expr
      assert_equal 10, expr3.value
      assert_instance_of LInt, expr3
    end

    # symbol
    StringIO.open("a bc") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal "a", expr1.name
      assert_instance_of LSymbol, expr1
      expr2 = parser.read_expr
      assert_equal "bc", expr2.name
      assert_instance_of LSymbol, expr2
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
      assert_instance_of LNil, expr1.cdr.cdr.cdr
      expr2 = parser.read_expr
      assert_equal "a", expr2.car.name
      assert_instance_of LNil, expr2.cdr
      expr3 = parser.read_expr
      assert_instance_of LNil, expr3
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
      assert_instance_of LTrue, expr1
      expr2 = parser.read_expr
      assert_instance_of LFalse, expr2
    end
  end
end

class TestExecuter < Minitest::Test
  include RbScheme

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
      assert_instance_of LInt, result
      assert_equal 10, result.value
    end

    # syntax_if
    StringIO.open("(if #t 1 2) (if #f 1 2)") do |strio|
      @executer.set_source!(strio)

      result1 = eval_next(@env)
      assert_instance_of LInt, result1
      assert_equal 1, result1.value
      result2 = eval_next(@env)
      assert_instance_of LInt, result2
      assert_equal 2, result2.value
    end

    # syntax_lambda
    StringIO.open("((lambda (x y) (* x y 2)) 5 7)") do |strio|
      @executer.set_source!(strio)

      result = eval_next(@env)
      assert_instance_of LInt, result
      assert_equal 70, result.value
    end

    # syntax_define
    StringIO.open("(define a (+ 1 2)) a") do |strio|
      @executer.set_source!(strio)

      eval_next(@env)
      result = eval_next(@env)
      assert_instance_of LInt, result
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
      assert_instance_of LFalse, result
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

    # function without args
    StringIO.open("(list)") do |strio|
      @executer.set_source!(strio)

      result = eval_next(@env)
      assert_instance_of LNil, result
    end
  end
end
