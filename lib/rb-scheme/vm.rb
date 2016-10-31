module RbScheme
  class VM
    include Helpers
    include Symbol

    def exec(acc, exp, env, rib, stack)
      loop do
        case exp.car
        when intern("halt")
          check_length!(exp.cdr, 0, "halt")
          return acc
        when intern("refer")
          check_length!(exp.cdr, 3, "refer")
          n, m, x = exp.cdr.to_a

          acc = lookup(n, m, env).car
          exp = x
        when intern("constant")
          check_length!(exp.cdr, 2, "constant")
          obj, x = exp.cdr.to_a

          acc = obj
          exp = x
        when intern("close")
          check_length!(exp.cdr, 2, "close")
          body, x = exp.cdr.to_a

          acc = closure(body, env)
          exp = x
        when intern("test")
          check_length!(exp.cdr, 2, "test")
          thenx, elsex = exp.cdr.to_a

          exp = acc ? thenx : elsex
        when intern("assign")
          check_length!(exp.cdr, 3, "assign")
          n, m, x = exp.cdr.to_a

          lookup(n, m, env).car = acc
          exp = x
        when intern("conti")
          check_length!(exp.cdr, 1, "conti")
          x = exp.cadr

          acc = continuation(stack)
          exp = x
        when intern("nuate")
          check_length!(exp.cdr, 2, "nuate")
          p, x = exp.cdr.to_a

          exp = x
          stack = restore_stack(p)
        when intern("frame")
          check_length!(exp.cdr, 2, "frame")
          ret, x = exp.cdr.to_a

          exp = x
          stack = push(ret, push(env, push(rib, stack)))
          rib = list
        when intern("argument")
          check_length!(exp.cdr, 1, "argument")
          x = exp.cadr

          exp = x
          rib = cons(acc, rib)
        when intern("apply")
          check_length!(exp.cdr, 0, "apply")
          cls_body, cls_env = acc.to_a

          exp = cls_body
          env = extend_env(cls_env, rib)
          rib = list
        when intern("return")
          check_length!(exp.cdr, 0, "return")

          exp = index(stack, 0)
          env = index(stack, 1)
          rib = index(stack, 2)
          stack = stack - 3
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

    def closure(body, env)
      list(body, env)
    end

    def continuation(stack_p)
      body = list(intern("refer"),
                  0,
                  0,
                  list(intern("nuate"),
                       save_stack(stack_p),
                       list(intern("return"))))
      closure(body, list)
    end

    def call_frame(exp, env, rib, stack)
      list(exp, env, rib, stack)
    end

    def extend_env(env, vals)
      cons(vals, env)
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

