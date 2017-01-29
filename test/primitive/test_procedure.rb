require 'helper'

class TestProcedure < Minitest::Test
  include RbScheme

  def setup
    @procedure = Primitive::Procedure.new(func: lambda {})
  end

  def test_parse_parameter_info
    [
      { func: lambda { |x| }, expect: { required: 1, list: nil } },
      { func: lambda { |x, y| }, expect: { required: 2, list: nil } },
      { func: lambda { |x, y, *l| }, expect: { required: 2, list: true } },
      { func: lambda { |*l| }, expect: { required: 0, list: true } },
    ].each do |pat|
      @procedure.send(:parse_parameter_info, pat[:func])
      assert_equal @procedure.required_arg_num, pat[:expect][:required]
      assert_equal @procedure.arg_list, pat[:expect][:list]
    end
  end

  def test_call
    [
      { func: lambda { |x| x }, args: [LInt.new(100)], expect: true },
    ].each do |pat|
      prim = Primitive::Procedure.new(func: pat[:func])
      assert_equal pat[:expect], !!prim.call(pat[:args])
    end
  end

  def test_call_error_message
    template = "primitive procedure %s: required %d arguments, got %d"
    list_arg_template = "primitive procedure %s: required at least %d arguments, got %d"
    [
      { input: { func: lambda { |x| x }, args: [], name: "fn1" },
        expect: sprintf(template, "fn1", 1, 0) },
      { input: { func: lambda { |x, y| x }, args: [LInt.new(10)], name: "fn2" },
        expect: sprintf(template, "fn2", 2, 1) },
      { input: { func: lambda { |x, *y| x }, args: [], name: "fn3" },
        expect: sprintf(list_arg_template, "fn3", 1, 0) },
    ].each do |pat|
      err = assert_raises(ArgumentError) do
        input = pat[:input]
        prim = Primitive::Procedure.new(name: input[:name], func: input[:func])
        prim.call(input[:args])
      end
      assert_equal pat[:expect], err.message
    end
  end

end
