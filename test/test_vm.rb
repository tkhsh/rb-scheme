require 'helper'

class TestVM < Minitest::Test
  include RbScheme
  include RbScheme::Helpers
  include RbScheme::Symbol

  def setup
    @executer = Executer.new(STDIN)
  end

  def eval_with(io)
    exp = Parser.read_expr(io)
    @executer.vm_eval(exp)
  end

  def test_vm_lambda
    [
      { literal: "((lambda (x) x) 1)", expect: LInt.new(1) },
      { literal: "((lambda (a b) ((lambda (x y) x) b 3)) 4 5)", expect: LInt.new(5) },
      { literal: "((lambda (a b) ((lambda (x y) (if #t a b)) b 3)) 4 5)", expect: LInt.new(4) },
      { literal: "((lambda (x) ((lambda (a b) (set! x 10) (+ b x)) 1 x)) 100)",
        expect: LInt.new(110) },
      { literal: "((lambda (a b) (set! a 10) (+ a b)) 1 2)",
        expect: LInt.new(12) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        expect = pat[:expect]
        assert_instance_of expect.class, result
        assert_equal expect.value, result.value
      end
    end
  end

  def test_vm_assign_free_variable
    [
      { literal: "((lambda (x) ((lambda (a b) (set! x 10)) 1 x)) 100)",
        expect: LInt.new(10) }
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        expect = pat[:expect]
        assert_instance_of expect.class, result
        assert_equal expect.value, result.value
      end
    end
  end

  def test_vm_literal
    [
      { literal: "'(1 2)", expect: list(LInt.new(1), LInt.new(2)) }
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_if
    [
      { literal: "(if #f 1 2)", expect: LInt.new(2) },
      { literal: "(if #t 1 2)", expect: LInt.new(1) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_call_with_cc
    # todo: 1. call/ccの内部で自由変数が無効になる問題
    #       2. call/ccをlambdaで囲うと継続でスタックを扱えない問題(エラーになる)
    #       (vm_eval ((lambda (x) (call/cc (lambda (s) (s 9)))) 4))
    [
      { literal: "(call/cc (lambda (s) (s 9)))", expect: LInt.new(9) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_set
    [
      { literal: "((lambda (x) (set! x 10)) 1)", expect: LInt.new(10) },
      { literal: "(set! + 100)", expect: LInt.new(100) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_define
    [
      { literal: "(define x 5)", expect: LInt.new(5) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_begin
    [
      { literal: "(begin (display 4))", expect: /^4$/ },
      { literal: "(begin (display 4) (display 5))", expect: /^45$/ },
      { literal: "(begin (display 4) (display 5) (display 6))", expect: /^456$/ },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        exp = Parser.read_expr(strio)
        assert_output(pat[:expect]) do
          @executer.vm_eval(exp)
        end
      end
    end

  end

  def test_vm_primitive_arithmetic
    [
      { literal: "(+ 2 3 4)", expect: LInt.new(9) },
      { literal: "(+ 2 3)", expect: LInt.new(5) },
      { literal: "(+ 2)", expect: LInt.new(2) },
      { literal: "(+)", expect: LInt.new(0) },
      { literal: "(- 3 2 1)", expect: LInt.new(0) },
      { literal: "(- 2 3)", expect: LInt.new(-1) },
      { literal: "(- 3)", expect: LInt.new(-3) },
      { literal: "(* 5 2 3)", expect: LInt.new(30) },
      { literal: "(* 5)", expect: LInt.new(5) },
      { literal: "(*)", expect: LInt.new(1) },
      { literal: "(/ 20 5 2)", expect: LInt.new(2) },
      { literal: "(/ 10 3)", expect: LInt.new(3) },
      { literal: "(/ 10)", expect: LInt.new(0) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_primitive_predicate
    [
      { literal: "(= 1 1)", expect: LTrue },
      { literal: "(= 1 3)", expect: LFalse },
      { literal: "(< 2 3)", expect: LTrue },
      { literal: "(> 2 3)", expect: LFalse },
      { literal: "(> 1 1)", expect: LFalse },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_instance_of pat[:expect], result
      end
    end
  end

  def test_vm_primitive_constructor
    [
      { literal: "(cons 2 3)", expect: cons(LInt.new(2), LInt.new(3)) },
      { literal: "(list)", expect: list },
      { literal: "(list 1)", expect: list(LInt.new(1)) },
      { literal: "(list 1 2)", expect: list(LInt.new(1), LInt.new(2)) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)

        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_primitive_list_accessor
    [
      { literal: "(car (cons 1 10))", expect: LInt.new(1) },
      { literal: "(cdr (cons 1 100))", expect: LInt.new(100) },
      { literal: "(cadr (list 1 2 3))", expect: LInt.new(2) },
      { literal: "(cddr (list 1 2 3))", expect: list(LInt.new(3)) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        result = eval_with(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_vm_primitive_print
    [
      { literal: "(display 2)", expect: /^2$/ },
      { literal: "(newline)", expect: /^\n$/ },
      { literal: "(print 10)", expect: /^10\n$/ },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        exp = Parser.read_expr(strio)
        assert_output(pat[:expect]) do
          @executer.vm_eval(exp)
        end
      end
    end
  end

  def test_vm_compound_proc_error
    template = "closure: required %d arguments, got %d"
    [
      { literal: "((lambda () 3) 1 2)", expect: sprintf(template, 0, 2) },
      { literal: "((lambda (x) x) 1 2)", expect: sprintf(template, 1, 2) },
      { literal: "((lambda (x y) 1) 2 3 4)", expect: sprintf(template, 2, 3) },
      { literal: "((lambda (x y) 1) 2)", expect: sprintf(template, 2, 1) },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        exp = Parser.read_expr(strio)
        err = assert_raises(ArgumentError) do
          @executer.vm_eval(exp)
        end
        assert_equal pat[:expect], err.message
      end
    end
  end

end
