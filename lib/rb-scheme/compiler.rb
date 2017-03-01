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
          check_min_length!(exp.cdr, 2, "lambda")
          param_info = parse_parameters(exp.cadr)
          vars = param_info[:vars]
          *body = exp.cddr.to_a

          local_bound = Set.new(vars)
          global_bound = Set.new(Global.global_variables)
          free = convert_to_list(find_free_body(body, local_bound.union(global_bound)))
          sets_body = find_sets_body(body, Set.new(vars))
          c = compile_lambda_body(body,
                                  cons(vars, free),
                                  sets_body.union(sets.intersection(free)),
                                  list(intern("return"), vars.count))
          collect_free(free,
                       env,
                       list(intern("close"),
                            vars.count,
                            param_info[:variadic?] ? 1 : 0,
                            free.count,
                            make_boxes(sets_body, vars, c),
                            nxt))
        when intern("begin")
          check_min_length!(exp.cdr, 1, "begin")
          *body = exp.cdr.to_a

          compile_lambda_body(body, env, sets, nxt)
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
                         lambda { |n| compile(x, env, sets, list(intern("assign-free"), n, nxt)) },
                         lambda { |k| compile(x, env, sets, list(intern("assign-global"), k, nxt)) })
        when intern("define")
          check_length!(exp.cdr, 2, "define")
          var, x = exp.cdr.to_a

          Global.put(var, nil)
          compile(x, env, sets, list(intern("assign-global"), var, nxt))
        when intern("call/cc")
          check_length!(exp.cdr, 1, "call/cc")
          x = exp.cadr

          cn = tail?(nxt) ?
            list(intern("shift"), 1, nxt.cadr, list(intern("apply"), 1)) :
            list(intern("apply"), 1)
          c = list(intern("conti"),
                   list(intern("argument"),
                        compile(x, env, sets, cn)))
          tail?(nxt) ? c : list(intern("frame"), nxt, c)
        else
          args = exp.cdr
          cn = tail?(nxt) ?
            list(intern("shift"), exp.cdr.count, nxt.cadr, list(intern("apply"), args.count)) :
            list(intern("apply"), args.count)
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

    def parse_parameters(param)
      case param
      when LSymbol
        return { vars: list(param), variadic?: true }
      when LCell
        return { vars: list, variadic?: false } if param.null?
        result = []
        target = param
        loop do
          result.push(target.car)
          target = target.cdr
          if !target.is_a?(LCell)
            result.push(target)
            return { vars: convert_to_list(result), variadic?: true }
          elsif target.null?
            return { vars: convert_to_list(result), variadic?: false }
          end
        end
      else
        raise "error"
      end
    end

    def compile_lambda_body(body, env, sets, ret)
      c = ret
      body.reverse_each do |exp|
        c = compile(exp, env, sets, c)
      end
      c
    end

    def find_sets_body(body, sets_vars)
      body.reduce(Set.new) do |whole_sets, exp|
        whole_sets.union(find_sets(exp, sets_vars))
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
          check_min_length!(exp.cdr, 2, "find_sets(lambda)")
          new_vars, *body = exp.cdr.to_a

          find_sets_body(body, vars.subtract(new_vars))
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
        when intern("define")
          raise "Only top level define is supported"
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

    def find_free_body(body, bound_variables)
      body.reduce(Set.new) do |whole_free, exp|
        whole_free.union(find_free(exp, bound_variables))
      end
    end

    def find_free(exp, bound_variables)
      case exp
      when LSymbol
        bound_variables.member?(exp) ? Set.new : Set.new(list(exp))
      when LCell
        case exp.car
        when intern("quote")
          Set.new
        when intern("lambda")
          check_min_length!(exp.cdr, 2, "find_free")
          vars, *body = exp.cdr.to_a

          find_free_body(body, bound_variables.union(Set.new(vars)))
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
        when intern("define")
          raise "Only top level define is supported"
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
      return nxt if vars.null?

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
                     lambda { |n| list(intern("refer-free"), n, nxt) },
                     lambda { |k| list(intern("refer-global"), k, nxt) })
    end

    def compile_lookup(var, env, return_local, return_free, return_global)
      unless env.null?
        locals = env.car
        locals.each_with_index do |l, n|
          return return_local.call(n) if l == var
        end

        free = env.cdr
        free.each_with_index do |f, n|
          return return_free.call(n) if f == var
        end
      end

      if Global.defined?(var)
        return return_global.call(var)
      end

      raise "#{var.name} isn't found in environment"
    end
  end # Compiler
end # RbScheme
