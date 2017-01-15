require 'helper'

class TestParser < Minitest::Test
  include RbScheme
  include TestHelper

  def setup
    @printer = Printer.new
    @evaluator = Evaluator.new
  end

  def eval_string(str_expr)
    @evaluator.vm_eval(parse_string(str_expr))
  end

  def test_print_lisp_object
    [
      { input: "15", expect: /^15$/ },
      { input: "'()", expect: /^\(\)$/ },
      { input: "'a", expect: /^a$/ },
      { input: "#t", expect: /^#t$/ },
      { input: "#f", expect: /^#f$/ },
      { input: "+", expect: /^#<subr>$/ },
      { input: "(lambda (x) x)", expect: /^#<closure>$/ },
      { input: "'(1 2 3)", expect: /^\(1 2 3\)$/ },
      { input: "(cons 1 2)", expect: /^\(1 . 2\)$/ },
      { input: "(cons 3 (cons 1 2))", expect: /^\(3 1 . 2\)$/ },
    ].each do |pat|
      obj = eval_string(pat[:input])
      assert_output(pat[:expect]) do
        @printer.print_lisp_object(obj)
      end
    end
  end

end
