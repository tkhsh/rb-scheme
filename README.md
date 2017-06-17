[![CircleCI](https://circleci.com/gh/tkhsh/rb-scheme/tree/master.svg?style=svg&circle-token=7033e7916629278437dfafc29e10f40973ee5cd3)](https://circleci.com/gh/tkhsh/rb-scheme/tree/master)

# RbScheme

An implementation of Scheme subset written in Ruby. It's based on the Stack-Based model introduced in [Three Implementation Models for Scheme](http://www.cs.indiana.edu/~dyb/papers/3imp.pdf) by R. Kent Dybvig. The model is implemented by a compiler and virtual machine.

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

# Usage

## Run

### repl
```
$ bin/rb-scheme
```

You can use  [rlwrap](https://github.com/hanslub42/rlwrap) for readline
```
$ rlwrap bin/rb-scheme
```

### with file
```
$ bin/rb-scheme examples/nqueen.scm
```

## primitives

- numeric(`+`, `-`, `*`, `/`)
- predicate(`=`, `<`, `>`, `null?`)
- lisp operations(`cons`, `car`, `cdr`, `list`)
- print(`display`, `newline`, `print`)

## examples

see `examples` folder

# Test

[bundler](http://bundler.io/) required
```
$ bundle install
$ rake test
```

# License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
