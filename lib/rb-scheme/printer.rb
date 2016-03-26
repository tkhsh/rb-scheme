require "yaml"

module RbScheme
  class Printer
    def print(obj)
      puts YAML.dump(obj)
    end
  end # Printer
end # RbScheme
