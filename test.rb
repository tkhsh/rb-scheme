require 'minitest/autorun'
require 'stringio'
require './rscheme'

class TestParser < Minitest::Test
  include RScheme

  def test_read_expr
    # integer
    StringIO.open("1 -1 10") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.value
      assert_equal Type::INT, expr1.type
      expr2 = parser.read_expr
      assert_equal -1, expr2.value
      assert_equal Type::INT, expr2.type
      expr3 = parser.read_expr
      assert_equal 10, expr3.value
      assert_equal Type::INT, expr3.type
    end

    # symbol
    StringIO.open("a bc") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal :a, expr1.name
      assert_equal Type::SYMBOL, expr1.type
      expr2 = parser.read_expr
      assert_equal :bc, expr2.name
      assert_equal Type::SYMBOL, expr2.type
    end

    # quote
    StringIO.open("'a '(a b c)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal :quote, expr1.car.name
      assert_equal Type::CELL, expr1.type
      expr2 = parser.read_expr
      assert_equal :quote, expr2.car.name
      assert_equal Type::CELL, expr2.type
    end

    # list
    StringIO.open("(1 2 3) (a) ()") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.car.value
      assert_equal 3, expr1.cdr.cdr.car.value
      assert_equal Type::NIL, expr1.cdr.cdr.cdr.type
      expr2 = parser.read_expr
      assert_equal :a, expr2.car.name
      assert_equal Type::NIL, expr2.cdr.type
      expr3 = parser.read_expr
      assert_equal Type::NIL, expr3.type
    end

    # dotted list
    StringIO.open("(1 . 2) (f 1 . 3)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.value
      expr2 = parser.read_expr
      assert_equal :f, expr2.car.name
      assert_equal 1, expr2.cdr.car.value
      assert_equal 3, expr2.cdr.cdr.value
    end

    # hash
    StringIO.open("#t #f") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal Type::TRUE, expr1.type
      expr2 = parser.read_expr
      assert_equal Type::FALSE, expr2.type
    end
  end
end
