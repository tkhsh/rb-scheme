module RbScheme
  module Helpers
    # Constructor
    def cons(car, cdr)
      LCell.new(car, cdr)
    end

    def acons(key, val, cdr)
      cons(cons(key, val), cdr)
    end

    def array_to_list(array)
      result = LNil
      array.reverse_each do |e|
        result = cons(e, result)
      end
      result
    end

    def boolean(value)
      value ? LTrue : LFalse
    end
  end
end # RbScheme
