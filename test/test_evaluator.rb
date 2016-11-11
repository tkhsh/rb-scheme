require 'helper'

class TestExecuter < Minitest::Test
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

    # syntax_vm_eval
    vm_eval_exprs = <<-EXPRS
    (vm_eval ((lambda (x) x) 1))
    (vm_eval ((lambda (a b) ((lambda (x y) x) b 3)) 4 5))
    (vm_eval '(1 2))
    (vm_eval (if #f 1 2))
    (vm_eval ((lambda (x) (call/cc (lambda (s) (s 9)))) 4))
    EXPRS
    # (vm_eval ((lambda (x) (set! x 10)) 1))
    # (vm_eval ((lambda (x) (if 1 x (set! x 2)))
    #           3))
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

      # (vm_eval '(1 2))
      result3 = eval_next(@env)
      assert_instance_of LCell, result3
      assert_equal 1, result3.car.value
      assert_equal 2, result3.cadr.value

      # (vm_eval (if #f 1 2))
      test_if = eval_next(@env)
      assert_instance_of LInt, test_if
      assert_equal 2, test_if.value

      # (vm_eval ((lambda (x) (set! x 10) x) 1))
      # result4 = eval_next(@env)
      # assert_equal 10, result4.value
      #
      # # (vm_eval ((lambda (x) (if 1 x (set! x 2)) x)
      # #           3))
      # result5 = eval_next(@env)
      # assert_equal 3, result5.value
      #
      # (vm_eval ((lambda (x) (call/cc (lambda (s) 3))) 4))
      result6 = eval_next(@env)
      assert_equal 9, result6.value
    end

  end
end

