module RbScheme
  module Helpers
    # Constructor
    def cons(car, cdr)
      LCell.new(car, cdr)
    end

    def acons(key, val, cdr)
      cons(cons(key, val), cdr)
    end

    def list(*args)
      convert_to_list(args)
    end

    def convert_to_list(array)
      result = LNil.instance
      array.reverse_each do |e|
        result = cons(e, result)
      end
      result
    end

    def boolean(value)
      value ? LTrue.instance : LFalse.instance
    end

    def check_length!(lst, n, name)
      c = lst.count
      unless c == n
        raise ArgumentError, "#{name}: wrong number of arguments(#{c} for #{n})"
      end
    end
  end
end # RbScheme
