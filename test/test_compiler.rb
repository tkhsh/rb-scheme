require 'helper'

class TestCompiler < Minitest::Test
  include RbScheme
  include RbScheme::Symbol
  include RbScheme::Helpers

  def setup
    @compiler = Compiler.new
  end

  def test_find_free_body
    [
      { literal: "((a b c) (x y))", vars: [intern("b"), intern("x")],
        expect: [intern("a"), intern("c"), intern("y")] },
      { literal: "((a b c) (a d))", vars: [intern("b"), intern("x")],
        expect: [intern("a"), intern("c"), intern("d")] },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        body = Parser.read_expr(strio)
        bound_variables = Set.new(pat[:vars])
        result = @compiler.find_free_body(body, bound_variables)
        assert_equal result, Set.new(pat[:expect])
      end
    end
  end

  def test_find_free
    [
      { literal: "(a)", vars: [intern("x"), intern("y")], expect: [intern("a")] },
      { literal: "('a)", vars: [], expect: [] },
      { literal: "(lambda (a) a)", vars: [intern("x")], expect: [] },
      { literal: "(if a b c)", vars: [intern("x"), intern("a")],
        expect: [intern("b"), intern("c")] },
      { literal: "(set! a b)", vars: [intern("x")],
        expect: [intern("a"), intern("b")] },
      { literal: "(call/cc (lambda (r) a))", vars: [intern("x")],
        expect: [intern("a")] },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        exp = Parser.read_expr(strio)
        vars = Set.new(pat[:vars])
        result = @compiler.find_free(exp, vars)
        assert_equal Set.new(pat[:expect]), result
      end
    end

  end

  def test_find_sets_body
    [
      { literal: "((a b c) (set! y 10))", vars: [intern("b"), intern("y")],
        expect: [intern("y")] },
      { literal: "((set! b 10) (set! b 10) (set! c 10))", vars: [intern("b"), intern("c")],
        expect: [intern("b"), intern("c")] },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        body = Parser.read_expr(strio)
        bound_variables = Set.new(pat[:vars])
        result = @compiler.find_sets_body(body, bound_variables)
        assert_equal result, Set.new(pat[:expect])
      end
    end

  end

  def test_find_sets
    [
      { literal: "1", vars: [intern("a"), intern("b")], expect: [] },
      { literal: "(set! a 2)", vars: [intern("a"), intern("b")], expect: [intern("a")] },
      { literal: "(lambda (c) (set! a 3))", vars: [intern("a"), intern("b")],
        expect: [intern("a")] },
      { literal: "(lambda (c) (set! c 3))", vars: [intern("a"), intern("b")],
        expect: [] },
    ].each do |pat|
      StringIO.open(pat[:literal]) do |strio|
        exp = Parser.read_expr(strio)
        vars = Set.new(pat[:vars])

        result = @compiler.find_sets(exp, vars)
        assert_equal Set.new(pat[:expect]), result
      end
    end
  end

  def test_make_boxes
    StringIO.open("((a b c) (b y c) nxt)") do |io|
      exp = Parser.read_expr io
      sets = Set.new(exp.car)
      vars = exp.cadr
      nxt = exp.caddr

      result = @compiler.make_boxes sets, vars, nxt
      assert result.list?
      assert_equal 3, result.count
      assert_equal "box", result.car.name
      assert_equal 0, result.cadr

      third = result.caddr
      assert_equal "box", third.car.name
      assert_equal 2, third.cadr
    end

    StringIO.open("((a b c) (x y) nxt)") do |io|
      exp = Parser.read_expr io
      sets = Set.new(exp.car)
      vars = exp.cadr
      nxt = exp.caddr

      result = @compiler.make_boxes sets, vars, nxt
      assert_equal LSymbol, result.class
      assert_equal "nxt", result.name
    end
  end

  def test_parse_parameters
    [
      { input: list, expect: { vars: list, variadic?: false } },
      { input: intern("a"), expect: { vars: list(intern("a")), variadic?: true } },
      { input: list(intern("a")), expect: { vars: list(intern("a")), variadic?: false } },
      { input: list(intern("a"), intern("b")),
        expect: { vars: list(intern("a"), intern("b")), variadic?: false } },
      { input: cons(intern("a"), intern("lst")),
        expect: { vars: list(intern("a"), intern("lst")), variadic?: true } },
    ].each do |pat|
      result = @compiler.parse_parameters(pat[:input])
      assert_equal pat[:expect][:vars], result[:vars]
      assert_equal pat[:expect][:variadic?], result[:variadic?]
    end
  end

end

