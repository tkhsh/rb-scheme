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

class TestLCell < Minitest::Test
  include RbScheme
  include RbScheme::Helpers
  include RbScheme::Symbol

  def test_equality_operator
    [
      { cell: list(LInt.new(1)), another: list(LInt.new(1)),
        expect: true },
      { cell: list(LInt.new(1)), another: list(LInt.new(2)),
        expect: false },
      { cell: list, another: list,
        expect: true },
      { cell: list(intern("a")), another: list(intern("a")),
        expect: true },
      { cell: list(intern("a")), another: list(intern("b")),
        expect: false },
      { cell: list(LInt.new(1), LInt.new(2)),
        another: list(LInt.new(1), LInt.new(2)),
        expect: true },
      { cell: list(LInt.new(1)),
        another: list(LInt.new(1), LInt.new(2)),
        expect: false },
      { cell: list(LInt.new(1)),
        another: LInt.new(1),
        expect: false },
      { cell: cons(LInt.new(1), LInt.new(2)),
        another: cons(LInt.new(1), LInt.new(2)),
        expect: true },
    ].each do |pat|
      result = pat[:cell] == pat[:another]
      assert_equal pat[:expect], result
    end
  end

end
