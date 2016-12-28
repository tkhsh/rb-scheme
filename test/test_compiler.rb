require 'helper'
require 'set'

class TestCompiler < Minitest::Test
  include RbScheme

  def setup
    @compiler = Compiler.new
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
