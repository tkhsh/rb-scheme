# RbScheme

An implementation of Scheme subset written in ruby. Based on The Stack-Based model in [Three Implementation Models for Scheme](http://www.cs.indiana.edu/~dyb/papers/3imp.pdf) chapter 4(by R. Kent Dybvig). The model is implemented by a compiler and virtual machine.

# Features

- first class closures
- global variables
- integers/symbols/cons cell/true/false
- variadic function
- call/cc(limitation exists)
- if
- basic arithmetic functions(+ - * /)
- set!
- tail call optimization

# Install

```
$ git clone https://github.com/tkhsh/rb-scheme.git
```

# Run

repl
```
$ bin/rb-scheme
```

with file
```
$ bin/rb-scheme examples/nqueen.scm
```

# Test

[bundler](http://bundler.io/) required
```
$ bundle install
$ rake test
```
