module RbScheme
  class Executer
    extend Forwardable
    include Helpers

    def_delegator :@parser, :read_expr
    def_delegator :@primitive, :initialize_vm_primitive!
    def_delegator :@evaluator, :vm_eval
    def_delegator :@printer, :print_lisp_object

    def self.run(source)
      new(source).exec
    end

    def initialize(source)
      set_source!(source)
      @primitive = Primitive.new
      @evaluator = Evaluator.new
      @printer = Printer.new
    end

    def set_source!(source)
      @source = source
      @parser = Parser.new(source)
    end

    def exit?(expr)
      expr.is_a?(LSymbol) && expr.name == "exit"
    end

    def exec
      initialize_vm_primitive!

      if File.file?(@source)
        exec_file
      else
        exec_repl
      end
    end

    def exec_file
      result = nil
      loop do
        expr = read_expr
        break if expr.nil?
        result = vm_eval(expr)
      end
      print_lisp_object(result)
    end

    def exec_repl
      loop do
        print "> "
        expr = read_expr
        return if expr.nil?
        return if exit?(expr)
        print_lisp_object(vm_eval(expr))
      end
    end
  end # Executer
end # RbScheme
