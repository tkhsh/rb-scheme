# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rb-scheme/version'

Gem::Specification.new do |spec|
  spec.name          = "rb-scheme"
  spec.version       = RbScheme::VERSION
  spec.authors       = ["tkhsh"]
  spec.email         = ["uki.thashi@gmail.com"]

  spec.summary       = %q{An implementation of Scheme written in Ruby.}
  spec.description   = %q{An implementation of Scheme subset written in Ruby. It's based on the Stack-Based model introduced in Three Implementation Models for Scheme(http://www.cs.indiana.edu/~dyb/papers/3imp.pdf) by R. Kent Dybvig. The model is implemented by a compiler and virtual machine.}
  spec.homepage      = "https://github.com/tkhsh/rb-scheme"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.10"
end
