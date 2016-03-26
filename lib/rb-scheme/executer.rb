module RbScheme
  class Executer
    extend Forwardable
    include Helpers

    def_delegator :@parser, :read_expr
    def_delegator :@primitive, :add_primitive!
    def_delegator :@evaluator, :eval
    def_delegator :@printer, :print

    def init_env
      cons(LNil, LNil)
    end

    def self.run
      new.exec
    end

    def initialize(source = STDIN)
      set_source!(source)
      @primitive = Primitive.new
      @evaluator = Evaluator.new
      @printer = Printer.new
    end

    def set_source!(source)
      @parser = Parser.new(source)
    end

    def exec
      env = init_env
      add_primitive!(env)

      loop do
        expr = read_expr
        return if expr.nil?
        print(eval(expr, env))
      end
    end
  end # Executer
end # RbScheme
