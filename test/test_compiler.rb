require 'helper'

class TestCompiler < Minitest::Test
  include RbScheme
  include RbScheme::Symbol

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
    StringIO.open("(a)") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new([intern("x"), intern("y")])
      result = @compiler.find_free(exp, vars)
      assert_equal 1, result.count
      assert_equal intern("a"), result.first
    end

    StringIO.open("('a)") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new
      result = @compiler.find_free(exp, vars)
      assert result.empty?
    end

    StringIO.open("(lambda (a) a)") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new([intern("x")])
      result = @compiler.find_free(exp, vars)
      assert result.empty?
    end

    StringIO.open("(if a b c)") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new([intern("x"), intern("a")])
      result = @compiler.find_free(exp, vars)
      assert_equal 2, result.count
      assert_equal Set.new([intern("b"), intern("c")]), result
    end

    StringIO.open("(set! a b)") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new([intern("x")])
      result = @compiler.find_free(exp, vars)
      assert_equal 2, result.count
      assert_equal Set.new([intern("a"), intern("b")]), result
    end

    StringIO.open("(call/cc (lambda (r) a))") do |strio|
      exp = Parser.read_expr(strio)
      vars = Set.new([intern("x")])
      result = @compiler.find_free(exp, vars)
      assert_equal 1, result.count
      assert_equal Set.new([intern("a")]), result
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
    StringIO.open("(lambda (a b) 1)") do |io|
      exp = Parser.read_expr io
      vars = exp.cadr
      body = exp.caddr

      result = @compiler.find_sets body, Set.new(vars)
      assert result.empty?
    end

    StringIO.open("(lambda (a b) (set! a 2))") do |io|
      exp = Parser.read_expr io
      vars = exp.cadr
      body = exp.caddr

      result = @compiler.find_sets body, Set.new(vars)
      assert_equal result.count, 1
      assert_equal result.first.class, LSymbol
      assert_equal result.first.name, "a"
    end

    StringIO.open("(lambda (a b) (lambda (c) (set! a 3)))") do |io|
      exp = Parser.read_expr io
      vars = exp.cadr
      body = exp.caddr

      result = @compiler.find_sets body, Set.new(vars)
      assert_equal result.count, 1
      assert_equal result.first.class, LSymbol
      assert_equal result.first.name, "a"
    end

    StringIO.open("(lambda (a b) (lambda (c) (set! c 3)))") do |io|
      exp = Parser.read_expr io
      vars = exp.cadr
      body = exp.caddr

      result = @compiler.find_sets body, Set.new(vars)
      assert result.empty?
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
end

