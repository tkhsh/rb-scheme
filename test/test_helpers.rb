require 'helper'

class TestHelpers < Minitest::Test
  include RbScheme
  include RbScheme::Helpers
  include TestHelper

  def test_check_legnth!
    [
      { lst: list(1, 2, 3), num: 3, name: "length_3" },
      { lst: list(1), num: 1, name: "length_1" },
      { lst: list(), num: 0, name: "length_0" },
    ].each do |pat|
      check_length!(pat[:lst], pat[:num], pat[:name])
      assert true
    end

    [
      { input: { lst: list(1, 2, 3), num: 4, name: "length_3" },
        expect: "length_3: wrong number of arguments(given 3, expected 4)" },
      { input: { lst: list(1), num: 0, name: "length_1" },
        expect: "length_1: wrong number of arguments(given 1, expected 0)" },
      { input: { lst: list(), num: 3, name: "length_0" },
        expect: "length_0: wrong number of arguments(given 0, expected 3)" },
    ].each do |pat|
      e = assert_raises(ArgumentError) do
        args = pat[:input]
        check_length!(args[:lst], args[:num], args[:name])
      end
      assert_equal pat[:expect], e.message
    end
  end

  def test_check_min_length!
    [
      { lst: list(1, 2, 3), num: 1, name: "min_2" },
      { lst: list(1), num: 0, name: "min_1" },
      { lst: list(), num: 0, name: "min_0" },
    ].each do |pat|
      check_min_length!(pat[:lst], pat[:num], pat[:name])
      assert true
    end

    [
      { input: { lst: list(1, 2, 3), num: 4, name: "length_3" },
        expect: "length_3: wrong number of arguments(given 3, expected 4..)" },
      { input: { lst: list(1), num: 5, name: "length_1" },
        expect: "length_1: wrong number of arguments(given 1, expected 5..)" },
      { input: { lst: list(), num: 1, name: "length_0" },
        expect: "length_0: wrong number of arguments(given 0, expected 1..)" },
    ].each do |pat|
      e = assert_raises(ArgumentError) do
        args = pat[:input]
        check_min_length!(args[:lst], args[:num], args[:name])
      end
      assert_equal pat[:expect], e.message
    end
  end

end
