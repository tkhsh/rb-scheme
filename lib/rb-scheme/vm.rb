module RbScheme
  class VM
    include Helpers
    include Symbol

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
        when intern("test")
          check_length!(exp.cdr, 2, "test")
          thenx, elsex = exp.cdr.to_a

          exp = LFalse === acc ? elsex : thenx
        when intern("conti")
          check_length!(exp.cdr, 1, "conti")
          x = exp.cadr

          acc = continuation(stack_p)
          exp = x
        when intern("nuate")
          check_length!(exp.cdr, 2, "nuate")
          p, x = exp.cdr.to_a

          exp = x
          stack_p = restore_stack(p)
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
        when intern("apply")
          check_length!(exp.cdr, 0, "apply")

          exp = closure_body(acc)
          frame_p = stack_p
          cls = acc
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

    def lookup(n, m, env)
      env.each_with_index do |rib, rib_idx|
        if rib_idx == n
          vals = rib

          m.times do
            vals = vals.cdr
          end

          return vals
        end
      end
    end

    def closure(body, n, stack_p)
      v = Array.new(n + 1)
      v[0] = body

      i = 0
      while i == n
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

    def extend_env(env, vals)
      cons(vals, env)
    end

    def find_link(n, env)
      n.times do
        env = index(env, -1)
      end
      env
    end

    def stack
      @stack ||= Array.new(1000)
    end

    def push(val, stack_p)
      stack[stack_p] = val
      stack_p + 1
    end

    OFFSET = 1

    def index(stack_p, i)
      stack[stack_p - (i + OFFSET)]
    end

    def index_set!(stack_p, i, val)
      stack[stack_p - (i + OFFSET)] = val
    end

    def save_stack(stack_p)
      v = Array.new(stack_p)
      i = 0
      until i == stack_p
        v[i] = stack[i]
        i += 1
      end
      v
    end

    def restore_stack(saved_stack)
      s = saved_stack.length
      i = 0
      until i == s do
        stack[i] = saved_stack[i]
        i += 1
      end
      s
    end
  end # VM
end # RbScheme

