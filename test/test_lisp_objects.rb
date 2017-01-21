require 'helper'

class TestLInt < Minitest::Test
  include RbScheme
  include RbScheme::Symbol

  def test_equality_operator
    [
      { int: LInt.new(1), another: LInt.new(2), expect: false },
      { int: LInt.new(1), another: LInt.new(1), expect: true },
      { int: LInt.new(10), another: LInt.new(10), expect: true },
      { int: LInt.new(10), another: intern("10"), expect: false },
    ].each do |pat|
      result = pat[:int] == pat[:another]
      assert_equal pat[:expect], result
    end
  end

end

