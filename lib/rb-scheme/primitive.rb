module RbScheme
  class Primitive
    extend Forwardable
    include Helpers
    include Symbol

    def_delegators :@evaluator, :eval, :lookup_variable
    def_delegator :@printer, :print
    def_delegator :@compiler, :compile
    def_delegator :@vm, :exec, :vm_exec

    def initialize
      @evaluator = Evaluator.new
      @printer = Printer.new
      @compiler = Compiler.new
      @vm = VM.new
    end

    def syntax_lambda
      lambda do |form, env|
        params = form.car
        body = form.cdr

        unless form.count > 1 && params.list? && body.list?
          raise "Malformed lambda"
        end

        params.each do |p|
          raise "lambda - parameters must be Symbol" unless LSymbol === p
        end

        LLambda.new(params, body, env)
      end
    end

    def syntax_quote
      lambda do |form, env|
        raise "Malformed quote" unless form.count == 1
        form.car
      end
    end

    def syntax_define
      lambda do |form, env|
        raise "Malformed define" unless form.count > 1
        sym = form.car
        body = form.cadr
        raise "define - value must be bound to Symbol" unless LSymbol === sym
        add_variable!(env, sym, eval(body, env))
        LNil.instance
      end
    end

    def syntax_define_macro
      lambda do |form, env|
        raise "Malformed define-macro" unless form.count > 1
        sym = form.car
        body = form.cadr
        raise "define-macro - value must be bound to Symbol" unless LSymbol === sym
        add_variable!(env, sym, LMacro.new(sym.name, eval(body, env)))
        LNil.instance
      end
    end

    def syntax_if
      lambda do |form, env|
        raise "Malformed if" if form.count < 2

        cond = eval(form.car, env)
        unless LFalse === cond
          eval(form.cadr, env)
        else
          eval(form.caddr, env)
        end
      end
    end

    def syntax_set!
      lambda do |form, env|
        unless form.count == 2 && LSymbol === form.car
          raise "Malformed set!"
        end

        bind = lookup_variable(form.car, env)
        value = eval(form.cadr, env)
        bind.cdr = value
        value
      end
    end

    def syntax_begin
      lambda do |form, env|
        last = LInt.new(0)
        form.each { |e| last = eval(e, env) } unless LNil === form
        last
      end
    end

    def syntax_vm_eval
      lambda do |form, env|
        vm_exec(list,
                compile(form.car, list(intern("halt"))),
                env,
                list,
                list)
      end
    end

    def subr_cons
      lambda do |args, env|
        raise unless args.count == 2
        cons(args.car, args.cadr)
      end
    end

    def subr_car
      lambda do |args, env|
        raise unless args.count == 1
        fst = args.first
        raise unless fst.list?
        fst.car
      end
    end

    def subr_cdr
      lambda do |args, env|
        raise unless args.count == 1
        fst = args.first
        raise unless fst.list?
        fst.cdr
      end
    end

    def subr_list
      lambda do |args, env|
        args
      end
    end

    def subr_eq?
      lambda do |args, evn|
        raise "Malformed eq?" unless args.count == 2
        args.car == args.cadr
      end
    end

    def subr_list?
      lambda do |args, env|
        raise "Malformed list?" unless args.count == 1
        fst = args.car
        return LFalse.instance unless LCell === fst
        boolean(fst.list?)
      end
    end

    def subr_pair?
      lambda do |args, env|
        raise "Malformed pair?" unless args.count == 1
        fst = args.car
        return LFalse.instance unless LCell === fst
        LTrue.instance
      end
    end

    def subr_null?
      lambda do |args, evn|
        raise "Malformed null?" unless args.count == 1
        fst = args.car
        boolean(LNil === fst)
      end
    end

    def arithmetic_proc(op)
      lambda do |args, env|
        args.each do |e|
          raise "#{op} supports only numbers" unless LInt === e
        end
        fst = args.first
        rest = args.drop(1)
        val = rest.reduce(fst.value) { |res, n| yield(res, n.value) }
        LInt.new(val)
      end
    end

    def subr_plus
      arithmetic_proc("+") { |res, n| res + n }
    end

    def subr_minus
      arithmetic_proc("-") { |res, n| res - n }
    end

    def subr_mul
      arithmetic_proc("*") { |res, n| res * n }
    end

    def subr_div
      arithmetic_proc("/") { |res, n| res / n }
    end

    def subr_num_equal
      lambda do |args, env|
        unless args.all? { |e| LInt === e }
          raise "= supports only numbers"
        end
        boolean(args.car.value == args.cadr.value)
      end
    end

    def subr_gt
      lambda do |args, env|
        unless args.all? { |e| LInt === e }
          raise "= supports only numbers"
        end
        boolean(args.car.value > args.cadr.value)
      end
    end

    def subr_lt
      lambda do |args, env|
        unless args.all? { |e| LInt === e }
          raise "= supports only numbers"
        end
        boolean(args.car.value < args.cadr.value)
      end
    end

    def subr_print
      lambda do |args, env|
        args.each { |i| print(eval(i, env)) }
        puts
        LNil.instance
      end
    end

    def add_variable!(env, sym, value)
      env.car = acons(sym, value, env.car)
    end

    def add_primitive!(env)
      add_syntax!(env, "lambda", syntax_lambda)
      add_syntax!(env, "quote", syntax_quote)
      add_syntax!(env, "define", syntax_define)
      add_syntax!(env, "define-macro", syntax_define_macro)
      add_syntax!(env, "if", syntax_if)
      add_syntax!(env, "set!", syntax_set!)
      add_syntax!(env, "begin", syntax_begin)
      add_syntax!(env, "vm_eval", syntax_vm_eval)
      add_subrutine!(env, "cons", subr_cons)
      add_subrutine!(env, "car", subr_car)
      add_subrutine!(env, "cdr", subr_cdr)
      add_subrutine!(env, "list", subr_list)
      add_subrutine!(env, "eq?", subr_eq?)
      add_subrutine!(env, "list?", subr_list?)
      add_subrutine!(env, "pair?", subr_pair?)
      add_subrutine!(env, "null?", subr_null?)
      add_subrutine!(env, "+", subr_plus)
      add_subrutine!(env, "-", subr_minus)
      add_subrutine!(env, "*", subr_mul)
      add_subrutine!(env, "/", subr_div)
      add_subrutine!(env, "=", subr_num_equal)
      add_subrutine!(env, ">", subr_gt)
      add_subrutine!(env, "<", subr_lt)
      add_subrutine!(env, "print", subr_print)
      # todo ...
    end

    def add_syntax!(env, name, p)
      env.car = acons(intern(name), LSyntax.new(name, p), env.car)
    end

    def add_subrutine!(env, name, p)
      env.car = acons(intern(name), LSubroutine.new(name, p), env.car)
    end

  end # Primitive
end # RbScheme
