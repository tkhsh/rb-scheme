module RbScheme
  class VM
    extend Forwardable
    include Helpers
    include Symbol
    include Global

    def_delegators :@stack, :push, :index, :index_set!, :save_stack, :restore_stack

    def initialize
      @stack = Stack.new
    end

    def exec(acc, exp, frame_p, cls, stack_p)
      loop do
        case exp.car
        when intern("halt")
          check_length!(exp.cdr, 0, "halt")
          return acc
        when intern("refer-local")
          check_length!(exp.cdr, 2, "refer-local")
          n, x = exp.cdr.to_a

          acc = index(frame_p, n)
          exp = x
        when intern("refer-free")
          check_length!(exp.cdr, 2, "refer-free")
          n, x = exp.cdr.to_a

          acc = index_closure(cls, n)
          exp = x
        when intern("refer-global")
          check_length!(exp.cdr, 2, "refer-free")
          key, x = exp.cdr.to_a

          acc = get_global(key)
          exp = x
        when intern("indirect")
          check_length!(exp.cdr, 1, "indirect")
          x = exp.cadr

          acc = acc.unbox
        when intern("constant")
          check_length!(exp.cdr, 2, "constant")
          obj, x = exp.cdr.to_a

          acc = obj
          exp = x
        when intern("close")
          check_length!(exp.cdr, 3, "close")
          n, body, x = exp.cdr.to_a

          acc = closure(body, n, stack_p)
          exp = x
          stack_p = stack_p - n
        when intern("box")
          check_length!(exp.cdr, 2, "box")
          n, x = exp.cdr.to_a

          index_set!(stack_p, n, Box.new(index(stack_p, n)))
          exp = x
        when intern("test")
          check_length!(exp.cdr, 2, "test")
          thenx, elsex = exp.cdr.to_a

          exp = LFalse === acc ? elsex : thenx
        when intern("assign-local")
          check_length!(exp.cdr, 2, "assign-local")
          n, x = exp.cdr.to_a

          index(frame_p, n).set_box!(acc)
          exp = x
        when intern("assign-free")
          check_length!(exp.cdr, 2, "assign-free")
          n, x = exp.cdr.to_a

          index_closure(cls, n).set_box!(acc)
          exp = x
        when intern("assign-global")
          check_length!(exp.cdr, 2, "assign-global")
          key, x = exp.cdr.to_a

          put_global(key, acc)
          exp = x
        when intern("conti")
          check_length!(exp.cdr, 1, "conti")
          x = exp.cadr

          acc = continuation(stack_p)
          exp = x
        when intern("nuate")
          check_length!(exp.cdr, 2, "nuate")
          saved_stack, x = exp.cdr.to_a

          exp = x
          stack_p = restore_stack(saved_stack)
        when intern("frame")
          check_length!(exp.cdr, 2, "frame")
          ret, x = exp.cdr.to_a

          exp = x
          stack_p = push(ret, push(frame_p, push(cls, stack_p)))
        when intern("argument")
          check_length!(exp.cdr, 1, "argument")
          x = exp.cadr

          exp = x
          stack_p = push(acc, stack_p)
        when intern("shift")
          check_length!(exp.cdr, 3, "shift")
          n, m, x = exp.cdr.to_a

          exp = x
          stack_p = shift_args(n, m, stack_p)
        when intern("apply")
          check_length!(exp.cdr, 1, "apply")
          arg_len = exp.cadr

          if primitive_procedure?(acc)
            acc = apply_primitive(acc, arg_len, stack_p)
            exp, frame_p, cls, stack_p = return_primitive(stack_p, arg_len)
          elsif compound_procedure?(acc)
            exp, frame_p, cls = apply_compound(acc, stack_p)
          else
            raise "invalid application"
          end
        when intern("return")
          check_length!(exp.cdr, 1, "return")
          n = exp.cadr
          s = stack_p - n

          exp = index(s, 0)
          frame_p = index(s, 1)
          cls = index(s, 2)
          stack_p = s - 3
        else
          raise "Unknown instruction - #{exp.car}"
        end
      end
    end

    def apply_primitive(fn, arg_len, stack_p)
      i = 0
      args = []
      arg_len.times do
        args.push(index(stack_p, i))
        i += 1
      end
      fn.call(*args)
    end

    def return_primitive(stack_p, arg_len)
      s = stack_p - arg_len
      # [exp, frame_p, cls, stack_p]
      [index(s, 0), index(s, 1), index(s, 2), s -3]
    end

    def apply_compound(acc, stack_p)
      # [exp, frame_p, cls]
      [closure_body(acc), stack_p, acc]
    end

    def primitive_procedure?(procedure)
      procedure.is_a?(Proc)
    end

    def compound_procedure?(procedure)
      procedure.is_a?(Array)
    end

    def shift_args(n, m, s)
      i = n - 1
      until i < 0
        index_set!(s, i + m, index(s, i))
        i -= 1
      end
      s - m
    end

    def closure(body, n, stack_p)
      v = Array.new(n + 1)
      v[0] = body

      i = 0
      until i == n
        v[i + 1] = index(stack_p, i)
        i += 1
      end
      v
    end

    def closure_body(cls)
      cls[0]
    end

    def index_closure(cls, n)
      cls[n + 1]
    end

    def continuation(stack_p)
      body = list(intern("refer-local"),
                  0,
                  list(intern("nuate"),
                       save_stack(stack_p),
                       list(intern("return"), 0)))
      closure(body, 0, stack_p)
    end

  end # VM
end # RbScheme

