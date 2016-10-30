module RbScheme
  class VM
    include Helpers
    include Symbol

    def exec(acc, nxt, env, rib, stack)
      loop do
        case nxt.car
        when intern("halt")
          check_length!(nxt.cdr, 0, "halt")
          return acc
        when intern("refer")
          var, x = nxt.cdr.to_a
          check_length!(nxt.cdr, 2, "refer")

          acc = lookup(var, env).car
          nxt = x
        when intern("constant")
          check_length!(nxt.cdr, 2, "constant")
          obj, x = nxt.cdr.to_a

          acc = obj
          nxt = x
        when intern("close")
          check_length!(nxt.cdr, 2, "close")
          body, x = nxt.cdr.to_a

          acc = closure(body, env)
          nxt = x
        when intern("test")
          check_length!(nxt.cdr, 2, "test")
          thenx, elsex = nxt.cdr.to_a

          nxt = acc ? thenx : elsex
        when intern("assign")
          var, x = nxt.cdr.to_a
          check_length!(nxt.cdr, 2, "assign")

          lookup(var, env).car = acc
          nxt = x
        when intern("conti")
          check_length!(nxt.cdr, 1, "conti")
          x = nxt.cadr

          acc = continuation(stack)
          nxt = x
        when intern("nuate")
          s, var = nxt.cdr.to_a
          check_length!(nxt.cdr, 2, "nuate")

          acc = lookup(var, env).car
          nxt = list(intern("return"))
          stack = s
        when intern("frame")
          check_length!(nxt.cdr, 2, "frame")
          ret, x = nxt.cdr.to_a

          nxt = x
          stack = call_frame(ret, env, rib, stack)
          rib = list
        when intern("argument")
          check_length!(nxt.cdr, 1, "argument")
          x = nxt.cadr

          nxt = x
          rib = cons(acc, rib)
        when intern("apply")
          check_length!(nxt.cdr, 0, "apply")
          cls_body, cls_env = acc.to_a

          nxt = cls_body
          env = extend_env(cls_env, rib)
          rib = list
        when intern("return")
          check_length!(nxt.cdr, 0, "return")
          s_nxt, s_env, s_rib, s_stack = stack.to_a

          nxt = s_nxt
          env = s_env
          rib = s_rib
          stack = s_stack
        else
          raise "Unknown instruction - #{nxt.car}"
        end
      end
    end

    def lookup(access, env)
      env.each_with_index do |rib, rib_idx|
        if rib_idx == access.car
          vals = rib

          access.cdr.times do
            vals = vals.cdr
          end

          return vals
        end
      end
    end

    def closure(body, env)
      list(body, env)
    end

    def continuation(current_stack)
      closure(list(intern("nuate"), current_stack, cons(0, 0)),
              list)
    end

    def call_frame(nxt, env, rib, stack)
      list(nxt, env, rib, stack)
    end

    def extend_env(env, vals)
      cons(vals, env)
    end

  end # VM
end # RbScheme

