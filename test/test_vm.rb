require 'helper'

class TestVM < Minitest::Test
  include RbScheme

  def setup
    @executer = Executer.new(STDIN)
    @env = @executer.init_env
    @executer.add_primitive!(@env)
  end

  def eval_next(env)
    expr = @executer.read_expr
    raise if expr.nil?
    @executer.eval(expr, env)
  end

  def test_vm_lambda
    vm_eval_exprs = <<-EXPRS
    (vm_eval ((lambda (x) x) 1))
    (vm_eval ((lambda (a b) ((lambda (x y) x) b 3)) 4 5))
    (vm_eval ((lambda (a b) ((lambda (x y) (if #t a b)) b 3)) 4 5))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (vm_eval ((lambda (x) x) 1))
      result1 = eval_next(@env)
      assert_instance_of LInt, result1
      assert_equal 1, result1.value

      # (vm_eval ((lambda (a b) ((lambda (x y) x) b 3)) 4 5))
      result2 = eval_next(@env)
      assert_instance_of LInt, result2
      assert_equal 5, result2.value

      # (vm_eval ((lambda (a b) ((lambda (x y) (if #t a b)) b 3)) 4 5))
      result3 = eval_next(@env)
      assert_instance_of LInt, result3
      assert_equal 4, result3.value
    end
  end

  def test_vm_literal
    vm_eval_exprs = <<-EXPRS
    (vm_eval '(1 2))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next(@env)
      assert_instance_of LCell, result
      assert_equal 1, result.car.value
      assert_equal 2, result.cadr.value
    end
  end

  def test_vm_if
    vm_eval_exprs = <<-EXPRS
    (vm_eval (if #f 1 2))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next(@env)
      assert_instance_of LInt, result
      assert_equal 2, result.value
    end
  end

  def test_vm_call_with_cc
    # todo: 1. call/ccの内部で自由変数が無効になる問題
    #       2. call/ccをlambdaで囲うと継続でスタックを扱えない問題(エラーになる)
    vm_eval_exprs = <<-EXPRS
    (vm_eval (call/cc (lambda (s) (s 9))))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next(@env)
      assert_equal 9, result.value
    end
  end

  def test_vm_set
    vm_eval_exprs = <<-EXPRS
    (vm_eval ((lambda (x) (set! x 10)) 1))
    (vm_eval (set! + 100))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (vm_eval ((lambda (x) (set! x 10)) 1))
      result = eval_next(@env)
      assert_equal 10, result.value

      # assign global variable
      # (vm_eval (set! + 100))
      result = eval_next(@env)
      assert_equal 100, result.value
    end
  end

  def test_vm_define
    vm_eval_exprs = <<-EXPRS
    (vm_eval (define x 5))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      result = eval_next(@env)
      assert_equal 5, result.value
    end
  end

  def test_vm_primitive_arithmetic
    vm_eval_exprs = <<-EXPRS
    (vm_eval (+ 2 3))
    (vm_eval (- 2 3))
    (vm_eval (* 5 10))
    (vm_eval (/ 10 3))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (vm_eval (+ 2 3))
      result1 = eval_next(@env)
      assert_equal 5, result1.value

      # (vm_eval (- 2 3))
      result2 = eval_next(@env)
      assert_equal -1, result2.value

      # (vm_eval (* 5 10))
      result3 = eval_next(@env)
      assert_equal 50, result3.value

      # (vm_eval (/ 10 3))
      result4 = eval_next(@env)
      assert_equal 3, result4.value
    end
  end

  def test_vm_primitive_predicate
    vm_eval_exprs = <<-EXPRS
    (vm_eval (< 2 3))
    (vm_eval (> 2 3))
    (vm_eval (> 1 1))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (vm_eval (< 2 3))
      result1 = eval_next(@env)
      assert_instance_of LTrue, result1

      # (vm_eval (> 2 3))
      result2 = eval_next(@env)
      assert_instance_of LFalse, result2

      # (vm_eval (> 1 1))
      result3 = eval_next(@env)
      assert_instance_of LFalse, result3
    end
  end

  def test_vm_primitive_constructor
    vm_eval_exprs = <<-EXPRS
    (vm_eval (cons 2 3))
    (vm_eval (car (cons 1 10)))
    (vm_eval (cdr (cons 1 100)))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (vm_eval (cons 2 3))
      result1 = eval_next(@env)
      assert_instance_of LCell, result1
      assert_equal 2, result1.car.value
      assert_equal 3, result1.cdr.value

      # (vm_eval (car (cons 1 10)))
      result2 = eval_next(@env)
      assert_instance_of LInt, result2
      assert_equal 1, result2.value

      # (vm_eval (cdr (cons 1 10)))
      result3 = eval_next(@env)
      assert_instance_of LInt, result3
      assert_equal 100, result3.value
    end
  end
end
