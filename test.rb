require 'minitest/autorun'
require 'stringio'
require './rscheme'

class TestParser < Minitest::Test
  include RScheme
  include RScheme::LispObject

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
  end
end
