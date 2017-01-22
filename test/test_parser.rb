require 'helper'

class TestParser < Minitest::Test
  include RbScheme
  include RbScheme::Helpers
  include RbScheme::Symbol

  def test_read_expr_integer
    [
      { input: "1", expect: LInt.new(1) },
      { input: "-1", expect: LInt.new(-1) },
      { input: "10", expect: LInt.new(10) },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_read_expr_symbol
    [
      { input: "a", expect: intern("a") },
      { input: "bc", expect: intern("bc") },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_read_expr_quote
    [
      { input: "'a", expect: list(intern("quote"), intern("a")) },
      { input: "'(a b c)",
        expect: list(intern("quote"),
                     list(intern("a"), intern("b"), intern("c"))) },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_read_expr_list
    [
      { input: "(1 2 3)", expect: list(LInt.new(1), LInt.new(2), LInt.new(3)) },
      { input: "(a)", expect: list(intern("a")) },
      { input: "()", expect: list() },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_read_expr_dotted_list
    [
      { input: "(1 . 2)", expect: cons(LInt.new(1), LInt.new(2)) },
      { input: "(f 1 . 3)", expect: cons(intern("f"), cons(LInt.new(1), LInt.new(3))) },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_equal pat[:expect], result
      end
    end
  end

  def test_read_expr_hash
    [
      { input: "#t", expect: LTrue },
      { input: "#f", expect: LFalse },
    ].each do |pat|
      StringIO.open(pat[:input]) do |strio|
        result = Parser.read_expr(strio)
        assert_instance_of pat[:expect], result
      end
    end
  end

end
