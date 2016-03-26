module RbScheme
  module Symbol
    @@symbols = {}

    def intern(name)
      key = name.to_sym
      return @@symbols[key] if @@symbols.has_key?(key)

      sym = LSymbol.new(name)
      @@symbols[key] = sym
      sym
    end
  end # Symbol
end # RbScheme
