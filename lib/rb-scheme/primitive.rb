module RbScheme
  class Primitive
    extend Forwardable
    include Helpers
    include Symbol

    def_delegators :@printer, :print_lisp_object, :puts_lisp_object

    def initialize
      @printer = Printer.new
    end

    def initialize_vm_primitive!
      put_primitive_proc("+", lambda do |*nums|
        sum = 0
        nums.each do |n|
          sum += n.value
        end
        LInt.new(sum)
      end)

      put_primitive_proc("-", lambda do |first, *rest|
        result = first.value
        if rest.any?
          rest.each do |n|
            result -= n.value
          end
        else
          result = -result
        end
        LInt.new(result)
      end)

      put_primitive_proc("*", lambda do |*nums|
        result = 1
        nums.each do |n|
          result *= n.value
        end
        LInt.new(result)
      end)

      put_primitive_proc("/", lambda do |first, *rest|
        result = first.value
        if rest.any?
          rest.each do |n|
            result /= n.value
          end
        else
          result = 1 / result
        end
        LInt.new(result)
      end)

      put_primitive_proc("=", lambda do |n1, n2|
        boolean(n1.value == n2.value)
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
        unless c.is_a?(LCell)
          raise ArgumentError, "pair required, but got #{c}"
        end
        c.car
      end)

      put_primitive_proc("cdr", lambda do |c|
        unless c.is_a?(LCell)
          raise ArgumentError, "pair required, but got #{c}"
        end
        c.cdr
      end)

      put_primitive_proc("list", lambda do |*lst|
        list(*lst)
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
      Global.put_global(intern(name), prim)
    end
  end # Primitive
end # RbScheme
