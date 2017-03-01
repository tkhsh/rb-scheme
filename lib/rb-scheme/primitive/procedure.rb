module RbScheme
  class Primitive
    class Procedure
      attr_reader :func, :name, :required_arg_num, :arg_list

      def initialize(attrs = {})
        @name = attrs[:name]
        @func = attrs[:func]
        parse_parameter_info(attrs[:func])
      end

      def call(args)
        check_arg_num!(args)
        func.call(*args)
      end

      private

        def parse_parameter_info(fn)
          @required_arg_num = 0
          fn.parameters.each do |p|
            param_type = p[0]
            case param_type
            when :req
              @required_arg_num += 1
            when :rest
              @arg_list = true
            end
          end
        end

        def check_arg_num!(args)
          if required_arg_num > args.count
            message = arg_list ?
              "primitive procedure #{name}: required at least #{required_arg_num} arguments, got #{args.count}" :
              "primitive procedure #{name}: required #{required_arg_num} arguments, got #{args.count}"
            raise ArgumentError, message
          end
        end
    end # Procedure
  end # Primitive
end # RbScheme
