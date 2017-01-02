module RbScheme
  class Compiler
    include Helpers
    include Symbol

    def compile(exp, env, sets, nxt)
      case exp
      when LSymbol
        compile_refer(exp,
                      env,
                      sets.member?(exp) ? list(intern("indirect"), nxt) : nxt)
      when LCell
        case exp.car
        when intern("quote")
          check_length!(exp.cdr, 1, "quote")
          obj = exp.cadr

          list(intern("constant"), obj, nxt)
        when intern("lambda")
          check_length!(exp.cdr, 2, "lambda")
          vars, body = exp.cdr.to_a

          free = convert_to_list(find_free(body, Set.new(vars)))
          sets_body = find_sets(body, Set.new(vars))
          c = compile(body,
                      cons(vars, free),
                      sets_body.union(sets.intersection(free)),
                      list(intern("return"), vars.count))
          collect_free(free,
                       env,
                       list(intern("close"),
                            free.count,
                            make_boxes(sets_body, vars, c),
                            nxt))
        when intern("if")
          check_length!(exp.cdr, 3, "if")
          test, then_exp, else_exp = exp.cdr.to_a

          thenc = compile(then_exp, env, sets, nxt)
          elsec = compile(else_exp, env, sets, nxt)
          compile(test, env, sets, list(intern("test"), thenc, elsec))
        when intern("set!")
          check_length!(exp.cdr, 2, "set!")
          var, x = exp.cdr.to_a

          compile_lookup(var,
                         env,
                         lambda { |n| compile(x, env, sets, list(intern("assign-local"), n, nxt)) },
                         lambda { |n| compile(x, env, sets, list(intern("assign-free"), n, nxt)) })
        when intern("call/cc")
          check_length!(exp.cdr, 1, "call/cc")
          x = exp.cadr

          cn = tail?(nxt) ?
            list(intern("shift"), 1, nxt.cadr, list(intern("apply"))) :
            list(intern("apply"))
          c = list(intern("conti"),
                   list(intern("argument"),
                        compile(x, env, sets, cn)))
          tail?(nxt) ? c : list(intern("frame"), nxt, c)
        else
          args = exp.cdr
          cn = tail?(nxt) ?
            list(intern("shift"), exp.cdr.count, nxt.cadr, list(intern("apply"))) :
            list(intern("apply"))
          c = compile(exp.car, env, sets, cn)

          args.each do |arg|
            c = compile(arg, env, sets, list(intern("argument"), c))
          end
          tail?(nxt) ? c : list(intern("frame"), nxt, c)
        end
      else
        list(intern("constant"), exp, nxt)
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

    def find_sets(exp, vars)
      case exp
      when LSymbol
        Set.new
      when LCell
        case exp.car
        when intern("quote")
          Set.new
        when intern("lambda")
          check_length!(exp.cdr, 2, "find_sets(lambda)")
          new_vars, body = exp.cdr.to_a

          find_sets(body, vars.subtract(new_vars))
        when intern("if")
          check_length!(exp.cdr, 3, "find_sets(if)")
          test, then_x, else_x = exp.cdr.to_a

          [test, then_x, else_x].inject(Set.new) do |res, x|
            res.union(find_sets(x, vars))
          end
        when intern("set!")
          check_length!(exp.cdr, 2, "find_sets(set!)")
          var, x = exp.cdr.to_a

          s = vars.member?(var) ? Set.new([var]) : Set.new
          s.union(find_sets(x, vars))
        when intern("call/cc")
          check_length!(exp.cdr, 1, "find_sets(call/cc)")
          x = exp.cadr

          find_sets(x, vars)
        else
          exp.inject(Set.new) do |res, x|
            res.union(find_sets(x, vars))
          end
        end
      else
        Set.new
      end
    end

    def make_boxes(sets, vars, nxt)
      n = vars.count - 1
      res = nxt

      vars.reverse_each do |v|
        if sets.member?(v)
          res = list(intern("box"), n, res)
        end
        n -= 1
      end
      res
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

          find_free(test_x, bound_variables)
            .union(find_free(then_x, bound_variables))
            .union(find_free(else_x, bound_variables))
        when intern("set!")
          check_length!(exp.cdr, 2, "find_free(set!)")
          var, exp = exp.cdr.to_a

          free = find_free(exp, bound_variables)
          bound_variables.member?(var) ? free : Set[var].union(free)
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
