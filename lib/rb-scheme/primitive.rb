module RbScheme
  class Primitive
    extend Forwardable
    include Helpers
    include Symbol
    include Global

    def_delegator :@printer, :print

    def initialize
      @printer = Printer.new
    end

    def initialize_vm_primitive!
      put_global(intern("+"), lambda do |n1, n2|
        LInt.new(n1.value + n2.value)
      end)

      put_global(intern("-"), lambda do |n1, n2|
        LInt.new(n1.value - n2.value)
      end)

      put_global(intern("*"), lambda do |n1, n2|
        LInt.new(n1.value * n2.value)
      end)

      put_global(intern("/"), lambda do |n1, n2|
        LInt.new(n1.value / n2.value)
      end)

      put_global(intern("<"), lambda do |n1, n2|
        boolean(n1.value < n2.value)
      end)

      put_global(intern(">"), lambda do |n1, n2|
        boolean(n1.value > n2.value)
      end)

      put_global(intern("null?"), lambda do |lst|
        boolean(lst.is_a?(LNil))
      end)

      put_global(intern("cons"), lambda do |e1, e2|
        cons(e1, e2)
      end)

      put_global(intern("car"), lambda do |c|
        c.car
      end)

      put_global(intern("cdr"), lambda do |c|
        c.cdr
      end)
      # todo...
    end

  end # Primitive
end # RbScheme
