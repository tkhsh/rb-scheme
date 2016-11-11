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
end

