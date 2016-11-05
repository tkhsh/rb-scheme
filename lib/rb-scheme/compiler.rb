require 'set'

module RbScheme
  class Compiler
    include Helpers
    include Symbol

    def compile(x, env, nxt)
      case x
      when LSymbol
        compile_lookup_old(x,
                           env,
                           lambda { |n, m| list(intern("refer"), n, m, nxt) })
      when LCell
        case x.car
        when intern("quote")
          check_length!(x.cdr, 1, "quote")
          obj = x.cadr

          list(intern("constant"), obj, nxt)
        when intern("lambda")
          check_length!(x.cdr, 2, "lambda")
          vars, body = x.cdr.to_a

          bodyc = compile(body,
                          extend_env(env, vars),
                          list(intern("return"), vars.count + 1))
          list(intern("close"), bodyc, nxt)
        when intern("if")
          check_length!(x.cdr, 3, "if")
          test, then_exp, else_exp = x.cdr.to_a

          thenc = compile(then_exp, env, nxt)
          elsec = compile(else_exp, env, nxt)
          compile(test, env, list(intern("test"), thenc, elsec))
        when intern("call/cc")
          check_length!(x.cdr, 1, "call/cc")
          exp = x.cadr

          c = list(intern("conti"),
                   list(intern("argument"),
                        compile(exp, env, list(intern("apply")))))
          list(intern("frame"), nxt, c)
        else
          args = x.cdr
          c = compile(x.car, env, list(intern("apply")))

          args.each do |arg|
            c = compile(arg, env, list(intern("argument"), c))
          end
          list(intern("frame"), nxt, c)
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

    def compile_lookup_old(var, env, ret)
      env.each_with_index do |rib, i|
        rib.each_with_index do |elt, j|
          return ret.call(i, j) if elt.equal?(var)
        end
      end
    end

    def find_free(exp, bound_variables)
      case exp
      when LSymbol
        bound_variables.member?(intern(exp.name)) ? Set.new : Set.new(list(exp))
      when LCell
        case exp.car
        when intern("quote")
          Set.new
        when intern("lambda")
          check_length!(exp.cdr, 2, "find_free(lambda)")
          vars, body = exp.cdr.to_a

          find_free(body, bound_variables.union(Set.new(vars)))
        when intern("if")
          check_length!(exp.cdr, 3, "find_free(if)")
          test_x, then_x, else_x = exp.cdr.to_a

          bound_variables.union(find_free(test_x))
                         .union(find_free(then_x))
                         .union(find_free(else_x))
        when intern("call/cc")
          check_length!(exp.cdr, 1, "find_free(call/cc)")
          x = exp.cadr

          find_free(x, bound_variables)
        else
          exp.inject(Set.new) do |result, item|
            result.union(find_free(item, bound_variables))
          end
        end
      else
        Set.new
      end
    end

    def collect_free(vars, env, nxt)
      return nxt if LNil === vars

      collect_free(vars.cdr,
                   env,
                   compile_refer(vars.car,
                                 env,
                                 list(intern("argument"), nxt)))
    end

    def compile_refer(var, env, nxt)
      compile_lookup(var,
                     env,
                     lambda { |n| list(intern("refer-local"), n, nxt) },
                     lambda { |n| list(intern("refer-free"), n, nxt) })
    end

    def compile_lookup(var, env, return_local, return_free)
      locals = env.car
      locals.each_with_index do |l, n|
        return return_local.call(n) if l == var
      end

      free = env.cdr
      free.each_with_index do |f, n|
        return return_free.call(n) if f == var
      end

      raise "compile_lookup - #{var} isn't found in environment"
    end
  end # Compiler
end # RbScheme
