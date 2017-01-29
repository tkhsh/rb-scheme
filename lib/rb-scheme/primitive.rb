module RbScheme
  class Primitive
    extend Forwardable
    include Helpers
    include Symbol
    include Global

    def_delegators :@printer, :print_lisp_object, :puts_lisp_object

    def initialize
      @printer = Printer.new
    end

    def initialize_vm_primitive!
      put_primitive_proc("+", lambda do |n1, n2|
        LInt.new(n1.value + n2.value)
      end)

      put_primitive_proc("-", lambda do |n1, n2|
        LInt.new(n1.value - n2.value)
      end)

      put_primitive_proc("*", lambda do |n1, n2|
        LInt.new(n1.value * n2.value)
      end)

      put_primitive_proc("/", lambda do |n1, n2|
        LInt.new(n1.value / n2.value)
      end)

      put_primitive_proc("<", lambda do |n1, n2|
        boolean(n1.value < n2.value)
      end)

      put_primitive_proc(">", lambda do |n1, n2|
        boolean(n1.value > n2.value)
      end)

      put_primitive_proc("null?", lambda do |lst|
        boolean(lst.is_a?(LCell) && lst.null?)
      end)

      put_primitive_proc("cons", lambda do |e1, e2|
        cons(e1, e2)
      end)

      put_primitive_proc("car", lambda do |c|
        c.car
      end)

      put_primitive_proc("cdr", lambda do |c|
        c.cdr
      end)

      put_primitive_proc("display", lambda do |obj|
        print_lisp_object(obj)
      end)

      put_primitive_proc("newline", lambda do
        print("\n")
      end)

      put_primitive_proc("print", lambda do |obj|
        puts_lisp_object(obj)
      end)
      # todo...
    end

    def put_primitive_proc(name, func)
      prim = Procedure.new(name: name, func: func)
      put_global(intern(name), prim)
    end

  end # Primitive
end # RbScheme
