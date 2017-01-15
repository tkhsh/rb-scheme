require 'helper'

class TestVM < Minitest::Test
  include RbScheme

  def setup
    @executer = Executer.new(STDIN)
  end

  def eval_next
    expr = @executer.read_expr
    raise if expr.nil?
    @executer.vm_eval(expr)
  end

  def test_vm_lambda
    vm_eval_exprs = <<-EXPRS
    ((lambda (x) x) 1)
    ((lambda (a b) ((lambda (x y) x) b 3)) 4 5)
    ((lambda (a b) ((lambda (x y) (if #t a b)) b 3)) 4 5)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # ((lambda (x) x) 1)
      result1 = eval_next
      assert_instance_of LInt, result1
      assert_equal 1, result1.value

      # ((lambda (a b) ((lambda (x y) x) b 3)) 4 5)
      result2 = eval_next
      assert_instance_of LInt, result2
      assert_equal 5, result2.value

      # ((lambda (a b) ((lambda (x y) (if #t a b)) b 3)) 4 5)
      result3 = eval_next
      assert_instance_of LInt, result3
      assert_equal 4, result3.value
    end
  end

  def test_vm_literal
    vm_eval_exprs = <<-EXPRS
    '(1 2)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next
      assert_instance_of LCell, result
      assert_equal 1, result.car.value
      assert_equal 2, result.cadr.value
    end
  end

  def test_vm_if
    vm_eval_exprs = <<-EXPRS
    (if #f 1 2)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next
      assert_instance_of LInt, result
      assert_equal 2, result.value
    end
  end

  def test_vm_call_with_cc
    # todo: 1. call/ccの内部で自由変数が無効になる問題
    #       2. call/ccをlambdaで囲うと継続でスタックを扱えない問題(エラーになる)
    vm_eval_exprs = <<-EXPRS
    (call/cc (lambda (s) (s 9)))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)
      result = eval_next
      assert_equal 9, result.value
    end
  end

  def test_vm_set
    vm_eval_exprs = <<-EXPRS
    ((lambda (x) (set! x 10)) 1)
    (set! + 100)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # ((lambda (x) (set! x 10)) 1)
      result = eval_next
      assert_equal 10, result.value

      # assign global variable
      # (set! + 100)
      result = eval_next
      assert_equal 100, result.value
    end
  end

  def test_vm_define
    vm_eval_exprs = <<-EXPRS
    (define x 5)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      result = eval_next
      assert_equal 5, result.value
    end
  end

  def test_vm_primitive_arithmetic
    vm_eval_exprs = <<-EXPRS
    (+ 2 3)
    (- 2 3)
    (* 5 10)
    (/ 10 3)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (+ 2 3)
      result1 = eval_next
      assert_equal 5, result1.value

      # (- 2 3)
      result2 = eval_next
      assert_equal -1, result2.value

      # (* 5 10)
      result3 = eval_next
      assert_equal 50, result3.value

      # (/ 10 3)
      result4 = eval_next
      assert_equal 3, result4.value
    end
  end

  def test_vm_primitive_predicate
    vm_eval_exprs = <<-EXPRS
    (< 2 3)
    (> 2 3)
    (> 1 1)
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (< 2 3)
      result1 = eval_next
      assert_instance_of LTrue, result1

      # (> 2 3)
      result2 = eval_next
      assert_instance_of LFalse, result2

      # (> 1 1)
      result3 = eval_next
      assert_instance_of LFalse, result3
    end
  end

  def test_vm_primitive_constructor
    vm_eval_exprs = <<-EXPRS
    (cons 2 3)
    (car (cons 1 10))
    (cdr (cons 1 100))
    EXPRS
    StringIO.open(vm_eval_exprs) do |strio|
      @executer.set_source!(strio)

      # (cons 2 3)
      result1 = eval_next
      assert_instance_of LCell, result1
      assert_equal 2, result1.car.value
      assert_equal 3, result1.cdr.value

      # (car (cons 1 10))
      result2 = eval_next
      assert_instance_of LInt, result2
      assert_equal 1, result2.value

      # (cdr (cons 1 10))
      result3 = eval_next
      assert_instance_of LInt, result3
      assert_equal 100, result3.value
    end
  end
end
