module RbScheme
  module Global
    @@global_table = {}

    def global_define?(key)
      raise unless key.is_a? LSymbol
      @@global_table.member?(key)
    end

    def put_global(key, value)
      raise unless key.is_a? LSymbol
      @@global_table[key] = value
      value
    end

    def get_global(key)
      raise unless key.is_a? LSymbol
      @@global_table[key]
    end

    def global_variables
      @@global_table.keys
    end
  end # Global
end
