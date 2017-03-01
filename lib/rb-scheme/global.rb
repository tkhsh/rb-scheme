module RbScheme
  module Global
    @@global_table = {}

    def self.defined?(key)
      raise unless key.is_a? LSymbol
      @@global_table.member?(key)
    end

    def self.put(key, value)
      raise unless key.is_a? LSymbol
      @@global_table[key] = value
      value
    end

    def self.get_global(key)
      raise unless key.is_a? LSymbol
      @@global_table[key]
    end

    def self.global_variables
      @@global_table.keys
    end
  end # Global
end
