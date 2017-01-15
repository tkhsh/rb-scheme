module RbScheme
  class Printer
    def puts_lisp_object(obj)
      print_lisp_object(obj)
      print "\n"
    end

    def print_lisp_object(obj)
      case obj
      when LInt
        print obj.value
      when LSymbol
        print obj.name
      when LNil
        print "()"
      when LTrue
        print "#t"
      when LFalse
        print "#f"
      when primitive_procedure
        print "#<subr>"
      when compound_procedure
        print "#<closure>"
      when LCell
        print "("
        loop do
          print_lisp_object(obj.car)
          case obj.cdr
          when LNil
            print(")")
            return
          when LCell
            print(" ")
            obj = obj.cdr
          else
            print(" . ")
            print_lisp_object(obj.cdr)
            print(")")
            return
          end
        end
      else
        raise "bug - error unexpected type #{obj}"
      end
    end

    def compound_procedure
      # expression (lambda ...) is compiled into Array
      Array
    end

    def primitive_procedure
      Proc
    end

  end # Printer
end # RbScheme
