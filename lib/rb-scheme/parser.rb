module RbScheme
  class Parser
    extend Forwardable
    include Helpers
    include Symbol

    EOF = nil

    def_delegator :@input, :getc

    def self.read_expr(input)
      new(input).read_expr
    end

    def initialize(input)
      @input = input
    end

    def peek
      c = getc
      @input.ungetc(c)
      c
    end

    def reverse_list(list)
      return LNil.instance if LNil === list
      list.reduce(LNil.instance) { |res, e| cons(e, res) }
    end

    def skip_line
      loop do
        c = getc
        case c
        when EOF, '\n'
          return
        when '\r'
          getc if '\n' == peek
          return
        end
      end
    end

    def read_list
      acc = LNil.instance
      loop do
        obj = read_expr
        raise "read_list: Unclosed parenthesis" if obj.nil?

        case obj
        when LCloseParen
          return reverse_list(acc)
        when LDot
          last = read_expr
          close = read_expr
          if close.nil? || !(LCloseParen === close)
            raise "read_list: Unclosed parenthesis"
          end
          if LNil === acc
            raise "read_list: dotted list must have car"
          end

          return acc.reduce(last) { |res, e| cons(e, res) }
        else
          acc = cons(obj, acc)
        end
      end
    end

    def read_quote
      sym = intern("quote")
      cons(sym, cons(read_expr, LNil.instance))
    end

    def read_number(value)
      result = value
      while /\d/ === peek
        result = result * 10 + getc.to_i
      end
      result
    end

    def read_hash
      c = getc
      case c
      when 't'
        LTrue.instance
      when 'f'
        LFalse.instance
      else
        raise "Unexpected hash literal #{c}"
      end
    end

    def read_symbol(first_char)
      result = first_char
      while symbol_rp === peek
        result += getc
      end
      intern(result)
    end

    def negative_number_pred
      Proc.new {|c| '-' == c && /\d/ === peek}
    end

    def symbol_rp
      allowed = '~!@$%^&*-_=+:/?<>'
      Regexp.new("[A-Za-z#{Regexp.escape(allowed)}]")
    end

    def read_expr
      loop do
        c = getc
        case c
        when /\s/
          next
        when EOF
          return nil
        when ';'
          skip_line
          next
        when '('
          return read_list
        when ')'
          return LCloseParen.instance
        when '.'
          return LDot.instance
        when '\''
          return read_quote
        when /\d/
          return LInt.new(read_number(c.to_i))
        when negative_number_pred
          return LInt.new(-read_number(c.to_i))
        when '#'
          return read_hash
        when symbol_rp
          return read_symbol(c)
        else
          raise "Unexpected character - #{c}"
        end
      end
    end

  end # Parser
end # RbScheme
