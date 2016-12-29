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

  def test_vm_eval
    # syntax_vm_eval
    vm_eval_exprs = <<-EXPRS
    (vm_eval ((lambda (x) x) 1))
    (vm_eval ((lambda (a b) ((lambda (x y) x) b 3)) 4 5))
    (vm_eval '(1 2))
    (vm_eval (if #f 1 2))
    (vm_eval ((lambda (x) (call/cc (lambda (s) (s 9)))) 4))
    (vm_eval ((lambda (x) (set! x 10)) 1))
    EXPRS
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

      # # (vm_eval ((lambda (x) (if 1 x (set! x 2)) x)
      # #           3))
      # result5 = eval_next(@env)
      # assert_equal 3, result5.value
      #
      # (vm_eval ((lambda (x) (call/cc (lambda (s) 3))) 4))
      result6 = eval_next(@env)
      assert_equal 9, result6.value

      # (vm_eval ((lambda (x) (set! x 10)) 1))
      test_assignment = eval_next(@env)
      assert_equal 10, test_assignment.value
    end
  end
end
