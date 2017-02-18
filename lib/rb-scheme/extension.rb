module RbScheme
  module Extension
    def self.initialize_compound!(evaluator)
      base = File.dirname(File.expand_path(__FILE__))
      definitions = File.join(base, "extension/procedures.scm")

      File.open(definitions) do |io|
        parser = Parser.new(io)
        loop do
          expr = parser.read_expr
          break if expr.nil?
          evaluator.vm_eval(expr)
        end
      end
    end
  end # Extension
end # RbScheme
