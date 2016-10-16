module RbScheme
  class Compiler
    include Helpers
    include Symbol

    def compile(x, env, nxt)
      case x
      when LSymbol
        list(intern("refer"), compile_lookup(x, env), nxt)
      when LCell
        case x.car
        when intern("quote")
          obj = x.cadr

          list(intern("constant"), obj, nxt)
        when intern("lambda")
          vars, body = x.cdr.to_a

          bodyc = compile(body, extend_env(env, vars), list(intern("return")))
          list(intern("close"), bodyc, nxt)
        when intern("if")
          test, then_exp, else_exp = x.cdr.to_a

          thenc = compile(then_exp, env, nxt)
          elsec = compile(else_exp, env, nxt)
          compile(test, env, list(intern("test"), thenc, elsec))
        when intern("set!")
          var, val = x.cdr.to_a

          access = compile_lookup(var, env)
          compile(val, env, list(intern("assign"), access, nxt))
        when intern("call/cc")
          exp = x.cadr

          c = list(intern("conti"),
                   list(intern("argument"),
                        compile(exp, env, list(intern("apply")))))
          tail?(nxt) ? c : list(intern("frame"), nxt, c)
        else
          args = x.cdr
          c = compile(x.car, env, list(intern("apply")))

          args.each do |arg|
            c = compile(arg, env, list(intern("argument"), c))
          end
          tail?(nxt) ? c : list(intern("frame"), nxt, c)
        end
      else
        list(intern("constant"), x, nxt)
      end
    end

    def tail?(nxt)
      nxt.car == intern("return")
    end

    def extend_env(env, var_rib)
      cons(var_rib, env)
    end

    def compile_lookup(var, env)
      env.each_with_index do |rib, i|
        rib.each_with_index do |elt, j|
          return cons(i, j) if elt.equal?(var)
        end
      end
    end

  end # Compiler
end # RbScheme
