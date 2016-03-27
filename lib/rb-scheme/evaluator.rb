module RbScheme
  class Evaluator
    include Helpers

    def lookup_variable(var, env)
      env.each do |frame|
        frame.each do |bind|
          return bind if var.name == bind.car.name
        end
      end

      raise "Unbound variable - #{var.name}"
    end

    def map_eval(lst, env)
      return LNil.instance unless lst.type == Type::CELL && lst.list?
      result_array = lst.map { |e| eval(e, env) }
      array_to_list(result_array)
    end

    def progn(expr_list, env)
      expr_list.map { |expr| eval(expr, env) }.last
    end

    def extend_env(env, vars, vals)
      frame = LNil.instance
      vars.to_a.zip(vals.to_a) do |var, val|
        frame = acons(var, val, frame)
      end
      cons(frame, env)
    end

    def apply(fn, args, env)
      extended = extend_env(env, fn.params, args)
      progn(fn.body, extended)
    end

    def eval(obj, env)
      case obj.type
      when Type::INT, Type::TRUE, Type::FALSE, Type::NIL
        obj
      when Type::SYMBOL
        lookup_variable(obj, env).cdr
      when Type::CELL
        raise "Invalid application" unless obj.list?

        fst = eval(obj.car, env)
        case fst.type
        when Type::SYNTAX
          fst.syntax.call(obj.cdr, env)
        when Type::SUBROUTINE
          args = map_eval(obj.cdr, env)
          fst.subr.call(args, env)
        when Type::LAMBDA
          args = map_eval(obj.cdr, env)
          apply(fst, args, env)
        when Type::MACRO
          expanded = apply(fst.form, obj.cdr, env)
          eval(expanded, env)
        else
          raise "application - unexpected type #{fst.type}"
        end
      else
        raise "Unexpected type - #{obj.type}"
      end
    end

  end # Evaluator
end # RbScheme
