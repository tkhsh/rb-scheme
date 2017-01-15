require "yaml"

module RbScheme
  class Printer
    def print_lisp_object(obj)
      puts YAML.dump(obj)
    end
  end # Printer
end # RbScheme
