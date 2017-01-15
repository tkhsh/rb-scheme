module RbScheme
  class Evaluator
    extend Forwardable
    include Helpers
    include Symbol

    def_delegator :@compiler, :compile
    def_delegator :@vm, :exec, :vm_exec

    def initialize
      @compiler = Compiler.new
      @vm = VM.new
      Primitive.new.initialize_vm_primitive!
    end

    def vm_eval(obj)
      c = compile(obj, list, Set.new, list(intern("halt")))
      vm_exec(list,
              c,
              0,
              list,
              0)
    end

  end # Evaluator
end # RbScheme
