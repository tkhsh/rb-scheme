require 'helper'

class TestParser < Minitest::Test
  include RbScheme

  def test_read_expr
    # integer
    StringIO.open("1 -1 10") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.value
      assert_instance_of LInt, expr1
      expr2 = parser.read_expr
      assert_equal -1, expr2.value
      assert_instance_of LInt, expr2
      expr3 = parser.read_expr
      assert_equal 10, expr3.value
      assert_instance_of LInt, expr3
    end

    # symbol
    StringIO.open("a bc") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal "a", expr1.name
      assert_instance_of LSymbol, expr1
      expr2 = parser.read_expr
      assert_equal "bc", expr2.name
      assert_instance_of LSymbol, expr2
    end

    # quote
    StringIO.open("'a '(a b c)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal "quote", expr1.car.name
      assert expr1.list?
      expr2 = parser.read_expr
      assert_equal "quote", expr2.car.name
      assert expr2.list?
    end

    # list
    StringIO.open("(1 2 3) (a) ()") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.car.value
      assert_equal 3, expr1.cdr.cdr.car.value
      assert_instance_of LNil, expr1.cdr.cdr.cdr
      expr2 = parser.read_expr
      assert_equal "a", expr2.car.name
      assert_instance_of LNil, expr2.cdr
      expr3 = parser.read_expr
      assert_instance_of LNil, expr3
    end

    # dotted list
    StringIO.open("(1 . 2) (f 1 . 3)") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_equal 1, expr1.car.value
      assert_equal 2, expr1.cdr.value
      expr2 = parser.read_expr
      assert_equal "f", expr2.car.name
      assert_equal 1, expr2.cdr.car.value
      assert_equal 3, expr2.cdr.cdr.value
    end

    # hash
    StringIO.open("#t #f") do |strio|
      parser = Parser.new(strio)

      expr1 = parser.read_expr
      assert_instance_of LTrue, expr1
      expr2 = parser.read_expr
      assert_instance_of LFalse, expr2
    end
  end
end
