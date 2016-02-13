require 'minitest/autorun'
require 'stringio'
require './rscheme'

class TestParser < Minitest::Test
  include RScheme
  include RScheme::LispObject

  def test_read_expr
    # todo
  end
end
