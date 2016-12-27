module RbScheme
  class VM
    module Stack

      def stack
        @stack ||= Array.new(1000)
      end

      def push(val, stack_p)
        stack[stack_p] = val
        stack_p + 1
      end

      OFFSET = 1

      def index(stack_p, i)
        stack[stack_p - (i + OFFSET)]
      end

      def index_set!(stack_p, i, val)
        stack[stack_p - (i + OFFSET)] = val
      end

      def save_stack(stack_p)
        v = Array.new(stack_p)
        i = 0
        until i == stack_p
          v[i] = stack[i]
          i += 1
        end
        v
      end

      def restore_stack(saved_stack)
        s = saved_stack.length
        i = 0
        until i == s do
          stack[i] = saved_stack[i]
          i += 1
        end
        s
      end

    end # Stack
  end # VM
end # RbScheme
