require 'minitest/autorun'
require 'stringio'
require 'rb-scheme'

module TestHelper
  include RbScheme

  def parse_string(str_expr)
    StringIO.open(str_expr) do |io|
      Parser.read_expr(io)
    end
  end

end
