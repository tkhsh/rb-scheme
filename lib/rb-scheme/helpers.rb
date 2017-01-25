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
      args.any? ? convert_to_list(args) : LCell.new
    end

    def convert_to_list(array)
      result = list
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
        raise ArgumentError, "#{name}: wrong number of arguments(given #{c}, expected #{n})"
      end
    end

    def check_min_length!(lst, min, name)
      c = lst.count
      unless c >= min
        raise ArgumentError, "#{name}: wrong number of arguments(given #{c}, expected #{min}..)"
      end
    end
  end
end # RbScheme
