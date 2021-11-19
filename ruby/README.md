<!-- # -*- coding: utf-8 -*- -->
# Oktest.rb README


Oktest.rb is a new-style testing library for Ruby.

* `ok {actual} == expected` style [assertion](#assertions).
* [Fixture injection](#fixture-injection) inspired by dependency injection.
* Structured test specifications like RSpec.
* [JSON Matcher](#json-matcher) similar to JSON Schema.
* [Filtering](#tag-and-filtering) testcases by pattern or tags.
* Blue/red color instead of green/red for accesability.
* Small code size (less than 3000 lines) and good performance.

```ruby
### Oktest                           ### Test::Unit
require 'oktest'                     #  require 'test/unit'
                                     #
Oktest.scope do                      #
                                     #
  topic "Example" do                 #  class ExampleTest < Test::Unit::TestCase
                                     #
    spec "...description..." do      #    def test_1     # ...description...
      ok {1+1} == 2                  #      assert_equal 2, 1+1
      not_ok {1+1} == 3              #      assert_not_equal 3, 1+1
      ok {3*3} < 10                  #      assert 3*3 < 10
      not_ok {3*4} < 10              #      assert 3*4 >= 10
      ok {@var}.nil?                 #      assert_nil @var
      not_ok {123}.nil?              #      assert_not_nil 123
      ok {3.14}.in_delta?(3.1, 0.1)  #      assert_in_delta 3.1, 3.14, 0.1
      ok {'aaa'}.is_a?(String)       #      assert_kind_of String, 'aaa'
      ok {'123'} =~ (/\d+/)          #      assert_match /\d+/, '123'
      ok {:sym}.same?(:sym)          #      assert_same? :sym, :sym
      ok {'README.md'}.file_exist?   #      assert File.file?('README.md')
      ok {'/tmp'}.dir_exist?         #      assert File.directory?('/tmp')
      ok {'/blabla'}.not_exist?      #      assert !File.exist?('/blabla')
      pr = proc { .... }             #      exc = assert_raise(Error) { .... }
      ok {pr}.raise?(Error, "mesg")  #      assert_equal "mesg", exc.message
    end                              #    end
                                     #
  end                                #  end
                                     #
end                                  #
```

Oktest.rb requires Ruby 2.0 or later.



## Table of Contents

<!-- TOC -->

  * <a href="#quick-tutorial">Quick Tutorial</a>
    * <a href="#install">Install</a>
    * <a href="#basic-example">Basic Example</a>
    * <a href="#assertion-failure-and-error">Assertion Failure, and Error</a>
    * <a href="#skip-and-todo">Skip and Todo</a>
    * <a href="#reporting-style">Reporting Style</a>
    * <a href="#run-all-test-scripts-under-directory">Run All Test Scripts Under Directory</a>
    * <a href="#tag-and-filtering">Tag and Filtering</a>
    * <a href="#case_when-and-case_else"><code>case_when</code> and <code>case_else</code></a>
    * <a href="#optional-unary-operators">Optional: Unary Operators</a>
    * <a href="#generate-test-code-skeleton">Generate Test Code Skeleton</a>
    * <a href="#defining-methods-in-topics">Defining Methods in Topics</a>
  * <a href="#assertions">Assertions</a>
    * <a href="#basic-assertions">Basic Assertions</a>
    * <a href="#predicate-assertions">Predicate Assertions</a>
    * <a href="#negative-assertion">Negative Assertion</a>
    * <a href="#exception-assertion">Exception Assertion</a>
    * <a href="#custom-assertion">Custom Assertion</a>
  * <a href="#fixtures">Fixtures</a>
    * <a href="#setup-and-teardown">Setup and Teardown</a>
    * <a href="#at_end-crean-up-handler"><code>at_end()</code>: Crean-up Handler</a>
    * <a href="#named-fixtures">Named Fixtures</a>
    * <a href="#fixture-injection">Fixture Injection</a>
    * <a href="#fixture-keyword-argument"><code>fixture:</code> keyword argument</a>
    * <a href="#global-scope">Global Scope</a>
  * <a href="#helpers">Helpers</a>
    * <a href="#capture_sio"><code>capture_sio()</code></a>
    * <a href="#dummy_file"><code>dummy_file()</code></a>
    * <a href="#dummy_dir"><code>dummy_dir()</code></a>
    * <a href="#dummy_values"><code>dummy_values()</code></a>
    * <a href="#dummy_attrs"><code>dummy_attrs()</code></a>
    * <a href="#dummy_ivars"><code>dummy_ivars()</code></a>
    * <a href="#recorder"><code>recorder()</code></a>
    * <a href="#partial_regexp"><code>partial_regexp()</code></a>
  * <a href="#json-matcher">JSON Matcher</a>
    * <a href="#simple-example">Simple Example</a>
    * <a href="#nested-example">Nested Example</a>
    * <a href="#complex-example">Complex Example</a>
    * <a href="#helper-methods-for-json-matcher">Helper Methods for JSON Matcher</a>
  * <a href="#tips">Tips</a>
    * <a href="#ok--in-minitest"><code>ok {}</code> in MiniTest</a>
    * <a href="#testing-rack-application">Testing Rack Application</a>
    * <a href="#environment-variale-oktest_rb">Environment Variale <code>$OKTEST_RB</code></a>
    * <a href="#traverser-class">Traverser Class</a>
    * <a href="#benchmarks">Benchmarks</a>
    * <a href="#--faster-option"><code>--faster</code> Option</a>
  * <a href="#change-log">Change Log</a>
  * <a href="#license-and-copyright">License and Copyright</a>

<!-- /TOC -->



## Quick Tutorial


### Install

```terminal
### install
$ gem install oktest
$ oktest --help

### create test directory
$ mkdir test

### create test script
$ oktest --skeleton > test/example_test.rb
$ less test/example_test.rb

### run test script
$ oktest -s verbose test
* Class
  * #method_name()
    - [pass] 1+1 should be 2.
    - [pass] fixture injection examle.
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.001s
```


### Basic Example

test/example01_test.rb:

```ruby
# coding: utf-8

require 'oktest'

class Hello
  def hello(name="world")
    return "Hello, #{name}!"
  end
end


Oktest.scope do

  topic Hello do

    topic '#hello()' do

      spec "returns greeting message." do
        actual = Hello.new.hello()
        ok {actual} == "Hello, world!"
      end

      spec "accepts user name." do
        actual = Hello.new.hello("RWBY")
        ok {actual} == "Hello, RWBY!"
      end

    end

  end

end
```

Result:

```terminal
$ oktest test/example01_test.rb   # or: ruby test/example01_test.rb
## test/example01_test.rb
* Hello
  * #hello()
    - [pass] returns greeting message.
    - [pass] accepts user name.
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

For accessibility reason, Oktest.rb prints passed test cases in blue color
instead of green color.
See https://accessibility.psu.edu/color/colorcoding/#RB for details.


### Assertion Failure, and Error

test/example02_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic 'other examples' do

    spec "example of assertion failure" do
      ok {1+1} == 2     # pass
      ok {1+1} == 0     # FAIL
    end

    spec "example of something error" do
      x = foobar        # NameError
    end

  end

end
```

Result:

```terminal
$ oktest test/example02_test.rb   # or: ruby test/example02_test.rb
## test/example02_test.rb
* other examples
  - [Fail] example of assertion failure
  - [ERROR] example of something error
----------------------------------------------------------------------
[Fail] other examples > example of assertion failure
    test/example02_test.rb:9:in `block (3 levels) in <main>'
        ok {1+1} == 0     # FAIL
$<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 0
----------------------------------------------------------------------
[ERROR] other examples > example of something error
    test/example02_test.rb:13:in `block (3 levels) in <main>'
        x = foobar        # NameError
NameError: undefined local variable or method `foobar' for #<#<Class:...>:...>
----------------------------------------------------------------------
## total:2 (pass:0, fail:1, error:1, skip:0, todo:0) in 0.000s
```


### Skip and Todo

test/example03_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic 'other examples' do

    spec "example of skip" do
      skip_when RUBY_VERSION < "3.0", "requires Ruby3"
      ok {1+1} == 2
    end

    spec "example of todo"    # spec without block means TODO

    spec "example of todo (when passed unexpectedly)" do
      TODO()                  # this spec should be failed,
                              # because not implemented yet.
      ok {1+1} == 2           # thefore if all assesions passed,
                              # it means 'unexpected success'.
    end

  end

end
```

Result:

```terminal
$ oktest test/example03_test.rb   # or: ruby test/example03_test.rb
## oktest test/example03_test.rb
* other examples
  - [Skip] example of skip (reason: requires Ruby3)
  - [TODO] example of todo
  - [Fail] example of todo (when passed unexpectedly)
----------------------------------------------------------------------
[Fail] other examples > example of todo (when passed unexpectedly)
    test/example03_test.rb:14:in `block (2 levels) in <top (required)>'
        spec "example of todo (when passed unexpectedly)" do
spec should be failed (because not implemented yet), but passed unexpectedly.
----------------------------------------------------------------------
## total:2 (pass:0, fail:1, error:0, skip:1, todo:1) in 0.000s
```


### Reporting Style

Verbose mode (default):

```terminal
$ oktest test/example01_test.rb -s verbose  # or -sv
## test/example01_test.rb
* Hello
  * #hello()
    - [pass] returns greeting message.
    - [pass] accepts user name.
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Simple mode:

```terminal
$ oktest test/example01_test.rb -s simple   # or -ss
## test/example01_test.rb
* Hello: 
  * #hello(): ..
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Compact mode:

```terminal
$ oktest test/example01_test.rb -s compact  # or -sc
test/example01_test.rb: ..
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Plain mode:

```terminal
$ oktest test/example01_test.rb -s plain    # or -sp
..
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Quiet mode:

```terminal
$ oktest test/example01_test.rb -s quiet    # or -sq

## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Quiet mode reports progress only of failed or error test cases (and doesn't
report progress of passed ones), so it's output is very compact. This is
very useful for large project which contains large number of test cases.

(Note: `ruby test/example01_test.rb -s <STYLE>` is also available.)


### Run All Test Scripts Under Directory

How to run test scripts under `test` directory:

```terminal
$ ls test/
example01_test.rb       example02_test.rb       example03_test.rb

$ oktest -s compact test  # or: ruby -r oktest -e 'Oktest.main' -- test -s compact
test/example01_test.rb: ..
test/example02_test.rb: fE
----------------------------------------------------------------------
[Fail] other examples > example of assertion failure
    test/example02_test.rb:9:in `block (3 levels) in <top (required)>'
        ok {1+1} == 0     # FAIL
    -e:1:in `<main>'
$<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 0
----------------------------------------------------------------------
[ERROR] other examples > example of something error
    test/example02_test.rb:13:in `block (3 levels) in <top (required)>'
        x = foobar        # NameError
    -e:1:in `<main>'
NameError: undefined local variable or method `foobar' for #<#<Class:...>:...>
----------------------------------------------------------------------
test/example03_test.rb: st
## total:6 (pass:2, fail:1, error:1, skip:1, todo:1) in 0.000s
```

Test script filename should be `test_xxx.rb` or `xxx_test.rb`
(not `test-xxx.rb` nor `xxx-test.rb`).


### Tag and Filtering

`scope()`, `topic()`, and `spec()` accepts tag name, for example 'obsolete'
or 'experimental'.

test/example04_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic 'Example topic' do

    topic Integer do
      spec "example #1" do
        ok {1+1} == 2
      end
      spec "example #2", tag: 'old' do     # tag name: 'old'
        ok {1-1} == 0
      end
    end

    topic Float, tag: 'exp' do             # tag name: 'exp'
      spec "example #3" do
        ok {1.0+1.0} == 2.0
      end
      spec "example #4" do
        ok {1.0-1.0} == 0.0
      end
    end

    topic String, tag: ['exp', 'old'] do   # tag name: 'old' and 'exp'
      spec "example #5" do
        ok {'a'*3} == 'aaa'
      end
    end

  end

end
```

It is possible to filter topics and specs by tag name or pattern.
Pattern (!= regular expression) supports `*`, `?`, `[]` and `{}`.

```terminal
$ oktest -F tag=exp         test/      # filter by tag name
$ oktest -F tag='*exp*'     test/      # filter by tag name pattern
$ oktest -F tag='{exp,old}' test/      # filter by multiple tag names
```

It is also possible to filter topics or specs by name.

```terminal
$ oktest -F topic='*Integer*' test/    # filter topics by pattern
$ oktest -F spec='*#[1-3]'    test/    # filter specs by pattern
```

If you need negative filter, use `!=` instead of `=`.

```terminal
$ oktest -F spec!='*#5'      test/     # exclude spec 'example #5'
$ oktest -F tag!='{exp,old}' test/     # exclude tag='exp' or tag='old'
```


### `case_when` and `case_else`

`case_when` and `case_else` represents conditional spec.

test/example05_test.rb:

```ruby
require 'oktest'

Oktest.scope do
  topic Integer do
    topic '#abs()' do

      case_when "value is negative..." do
        spec "converts value into positive." do
          ok {-123.abs()} == 123
        end
      end

      case_when "value is zero..." do
        spec "returns zero." do
          ok {0.abs()} == 0
        end
      end

      case_else do
        spec "returns itself." do
          ok {123.abs()} == 123
        end
      end

    end
  end
end
```

Result:

```terminal
$ ruby test/example05_test.rb
## test/example05_test.rb
* Integer
  * #abs()
    - When value is negative...
      - [pass] converts value into positive.
    - When value is zero...
      - [pass] returns zero.
    - Else
      - [pass] returns itself.
## total:3 (pass:3, fail:0, error:0, skip:0, todo:0) in 0.001s
```


### Optional: Unary Operators

`topic()` accepts unary plus (`+`) and `spec()` accepts unary minus (`-`).
This makes test scripts more readable.

<!--
test/example06_test.rb:
-->

```ruby
require 'oktest'

Oktest.scope do

+ topic('example') do            # unary `+` operator

  + topic('example') do          # unary `+` operator

    - spec("1+1 is 2.") do       # unary `-` operator
        ok {1+1} == 2
      end

    - spec("1*1 is 1.") do       # unary `-` operator
        ok {1*1} == 1
      end

    end

  end

end
```


### Generate Test Code Skeleton

`oktest --generate` (or `oktest -G`) generates test code skeleton from ruby file.
Comment line starting with `#;` is regarded as spec description.

hello.rb:

```ruby
class Hello

  def hello(name=nil)
    #; default name is 'world'.
    if name.nil?
      name = "world"
    end
    #; returns greeting message.
    return "Hello, #{name}!"
  end

end
```

Generate test code skeleton:

```terminal
$ oktest --generate hello.rb > test/hello_test.rb
```

test/hello_test.rb:

```ruby
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello()' do

      spec "default name is 'world'."

      spec "returns greeting message."

    end  # #hello()


  end  # Hello


end
```

(Experimental) `--generate=unaryop` generates test skeleton with unary operator `+` and `-`.

```terminal
$ oktest --generate=unaryop hello.rb > test/hello2_test.rb
```

test/hello2_test.rb:

```ruby
# coding: utf-8

require 'oktest'

Oktest.scope do


+ topic(Hello) do


  + topic('#hello()') do

    - spec("default name is 'world'.")

    - spec("returns greeting message.")

    end  # #hello()


  end  # Hello


end
```


### Defining Methods in Topics

Methods defined in topics can be called in specs.

<!--
test/example08a_test.rb:
-->

```ruby
require 'oktest'
Oktest.scope do

  topic "Method example" do

    def hello()                 # define method in topic block
      return "Hello!"
    end

    spec "example" do
      s = hello()               # call it in spec block
      ok {s} == "Hello!"
    end

  end

end
```

* It is OK to call methods defined in parent topics.
* It will be ERROR to call methods defined in child topics.

<!--
test/example08b_test.rb:
-->

```ruby
require 'oktest'
Oktest.scope do

+ topic('Outer') do

  + topic('Middle') do

      def hello()              # define method in topic block
        return "Hello!"
      end

    + topic('Inner') do

      - spec("inner spec") do
          s = hello()          # OK: call method defined in parent topic
          ok {s} == "Hello!"
        end

      end

    end

  - spec("outer spec") do
      s = hello()              # ERROR: call method defined in child topic
      ok {x} == "Hello!"
    end

  end

end
```



## Assertions


### Basic Assertions

In the following example, `a` means actual value and `e` means expected value.

<!--
test/example11_test.rb:
-->

```ruby
ok {a} == e              # fail unless a == e
ok {a} != e              # fail unless a != e
ok {a} === e             # fail unless a === e
ok {a} !== e             # fail unless a !== e

ok {a} >  e              # fail unless a > e
ok {a} >= e              # fail unless a >= e
ok {a} <  e              # fail unless a < e
ok {a} <= e              # fail unless a <= e

ok {a} =~ e              # fail unless a =~ e
ok {a} !~ e              # fail unless a !~ e

ok {a}.same?(e)          # fail unless a.equal?(e)
ok {a}.in?(e)            # fail unless e.include?(a)
ok {a}.in_delta?(e, x)   # fail unless e-x < a < e+x
ok {a}.truthy?           # fail unless !!a == true
ok {a}.falsy?            # fail unless !!a == false

ok {a}.file_exist?       # fail unless File.file?(a)
ok {a}.dir_exist?        # fail unless File.directory?(a)
ok {a}.symlink_exist?    # fail unless File.symlink?(a)
ok {a}.not_exist?        # fail unless ! File.exist?(a)

ok {a}.attr(name, e)     # fail unless a.__send__(name) == e
ok {a}.keyval(key, e)    # fail unless a[key] == e
ok {a}.item(key, e)      # alias of `ok {a}.keyval(key, e)`
ok {a}.length(e)         # fail unless a.length == e
```

It is possible to chain method call of `.attr()` and `.keyval()`.

<!--
test/example11b_test.rb:
-->

```ruby
ok {a}.attr(:name1, 'val1').attr(:name2, 'val2').attr(:name3, 'val3')
ok {a}.keyval(:key1, 'val1').keyval(:key2, 'val2').keyval(:key3, 'val3')
```


### Predicate Assertions

`ok {}` handles predicate methods (such as `.nil?`, `.empty?`, or `.key?`) automatically.

<!--
test/example12_test.rb:
-->

```ruby
ok {a}.nil?              # same as ok {a.nil?} == true
ok {a}.empty?            # same as ok {a.empty?} == true
ok {a}.key?(e)           # same as ok {a.key?(e)} == true
ok {a}.is_a?(e)          # same as ok {a.is_a?(e)} == true
ok {a}.include?(e)       # same as ok {a.include?(e)} == true
ok {a}.between?(x, y)    # same as ok {a.between?(x, y)} == true
```

`Pathname()` is a good example of predicate methods.
See [pathname.rb](https://ruby-doc.org/stdlib-2.7.0/libdoc/pathname/rdoc/Pathname.html)
document for details about `Pathname()`.

<!--
test/example12b_test.rb:
-->

```ruby
require 'pathname'      # !!!!!

ok {Pathname(a)}.owned?      # same as ok {Pathname(a).owned?} == true
ok {Pathname(a)}.readable?   # same as ok {Pathname(a).readable?} == true
ok {Pathname(a)}.writable?   # same as ok {Pathname(a).writable?} == true
ok {Pathname(a)}.absolute?   # same as ok {Pathname(a).absolute?} == true
ok {Pathname(a)}.relative?   # same as ok {Pathname(a).relative?} == true
```


### Negative Assertion

<!--
test/example13_test.rb:
-->

```ruby
not_ok {a} == e          # fail if a == e
ok {a}.NOT == e          # fail if a == e

not_ok {a}.file_exist?   # fail if File.file?(a)
ok {a}.NOT.file_exist?   # fail if File.file?(a)
```


### Exception Assertion

If you want to assert whether exception raised or not:

<!--
test/example14_test.rb:
-->

```ruby
pr = proc do
  "abc".len()        # raises NoMethodError
end
ok {pr}.raise?(NoMethodError)
ok {pr}.raise?(NoMethodError, "undefined method `len' for \"abc\":String")
ok {pr}.raise?(NoMethodError, /^undefined method `len'/)
ok {pr}.raise?       # pass if any exception raised, fail if nothing raised

## get exception object
ok {pr}.raise?(NoMethodError) {|exc|
  ok {exc.class}   == NoMethodError
  ok {exc.message} == "undefined method `len' for \"abc\":String"
}

## assert that procedure does NOT raise any exception
ok {pr}.NOT.raise?   # no exception class nor error message
not_ok {pr}.raise?   # same as above

## assert that procedure throws symbol.
pr2 = proc do
  throw :quit
end
ok {pr2}.throw?(:quit)  # pass if :quit thrown, fail if other or nothing thrown
```

If procedure contains `raise "errmsg"` instead of `raise ErrorClass, "errmsg"`,
you can omit exception class such as `ok {pr}.raise?("errmsg")`.

<!--
test/example14b_test.rb:
-->

```ruby
pr = proc do
  raise "something wrong"           # !!! error class not specified !!!
end
ok {pr}.raise?("something wrong")   # !!! error class not specified !!!
```

Notice that `ok().raise?()` compares error class by `==` operator, not `.is_a?` method.

<!--
test/example14c_test.rb:
-->

```ruby
pr = proc { 1/0 }     # raises ZeroDivisionError

ok {pr}.raise?(ZeroDivisoinError)   # pass
ok {pr}.raise?(StandardError)       # ERROR: ZeroDivisionError raised
ok {pr}.raise?(Exception)           # ERROR: ZeroDivisionError raised
```

This is an intended design to avoid unexpected assertion success.
For example, `assert_raises(NameError) { .... }` in MiniTest will result in
success unexpectedly even if `NoMethodError` raised in the block, because
`NoMethodError` is a subclass of `NameError`.

<!--
test/example14d_test.rb:
-->

```ruby
require 'minitest/spec'
require 'minitest/autorun'

describe "assert_raise()" do
  it "results in success unexpectedly" do
    ## catches NameError and it's subclasses, including NoMethodError.
    assert_raises(NameError) do   # catches NoMethodError, too.
      "str".foobar()              # raises NoMethodError.
    end
  end
end
```

Oktest.rb can avoid this pitfall, because `.raise?()` compares error class
by `==` operator, not `.is_a?` method.

<!--
test/example14e_test.rb:
-->

```ruby
require 'oktest'

Oktest.scope do
  topic 'ok().raise?' do
    spec "doesn't catch subclasses." do
      pr = proc do
        "str".foobar()      # raises NoMethodError
      end
      ok {pr}.raise?(NoMethodError)   # pass
      ok {pr}.raise?(NameError)       # NoMethodError raised intendedly
    end
  end
end
```

To catch subclass of error class, invoke `.raise!` instead of `.raise?`.
For example: `ok {pr}.raise!(NameError, /foobar/)`.

<!--
test/example14f_test.rb:
-->

```ruby
require 'oktest'

Oktest.scope do
  topic 'ok().raise!' do
    spec "catches subclasses." do
      pr = proc do
        "str".foobar()      # raises NoMethodError
      end
      ok {pr}.raise!(NoMethodError)   # pass
      ok {pr}.raise!(NameError)       # pass !!!!!
    end
  end
end
```


### Custom Assertion

How to define custom assertion:

<!--
test/example15_test.rb:
-->
```ruby
require 'oktest'

Oktest::AssertionObject.class_eval do
  def readable?     # custom assertion: file readable?
    _done()
    result = File.readable?(@actual)
    __assert(result == @bool) {
      "File.readable?($<actual>) == #{@bool}: failed.\n" +
      "    $<actual>:   #{@actual.inspect}"
    }
    self
  end
end

Oktest.scope do

  topic "Custom assertion" do

    spec "example spec" do
      ok {__FILE__}.readable?     # custom assertion
    end

  end

end
```



## Fixtures


### Setup and Teardown

test/example21a_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "Fixture example" do

    before do       # equivarent to setUp()
      puts "=== before() ==="
    end

    after do        # equivarent to tearDown()
      puts "=== after() ==="
    end

    before_all do   # equivarent to setUpAll()
      puts "*** before_all() ***"
    end

    after_all do    # equvarent to tearDownAll()
      puts "*** after_all() ***"
    end

    spec "example spec #1" do
      puts "---- example spec #1 ----"
    end

    spec "example spec #2" do
      puts "---- example spec #2 ----"
    end

  end

end
```

Result:

```terminal
$ oktest -s plain test/example21_test.rb
*** before_all() ***
=== before() ===
---- example spec #1 ----
=== after() ===
.=== before() ===
---- example spec #2 ----
=== after() ===
.*** after_all() ***

## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

These blocks can be defined per `topic()` or `scope()`.

* `before` block in outer topic/scope is called prior to `before` block in inner topic.
* `after` block in inner topic is called prior to `after` block in outer topic/scope.

test/example21b_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic 'Outer' do
    before { puts "=== Outer: before ===" }         # !!!!!
    after  { puts "=== Outer: after ===" }          # !!!!!

    topic 'Middle' do
      before { puts "==== Middle: before ====" }    # !!!!!
      after  { puts "==== Middle: after ====" }     # !!!!!

      topic 'Inner' do
        before { puts "===== Inner: before =====" } # !!!!!
        after  { puts "===== Inner: after =====" }  # !!!!!

        spec "example" do
          ok {1+1} == 2
        end

      end

    end

  end

end
```

Result:

```terminal
$ oktest -s plain test/example21b_test.rb
=== Outer: before ===
==== Middle: before ====
===== Inner: before =====
===== Inner: after =====
==== Middle: after ====
=== Outer: after ===
.
## total:1 (pass:1, fail:0, error:0, skip:0, todo:0) in 0.000s
```

If something error raised in `before`/`after`/`before_all`/`after_all` blocks,
test script execution will be stopped instantly.


### `at_end()`: Crean-up Handler

It is possible to register clean-up operation with `at_end()`.

test/example22_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "Auto clean-up" do

    spec "example spec" do
      tmpfile = "tmp123.txt"
      File.write(tmpfile, "foobar\n")
      at_end do                # register clean-up operation
        File.unlink(tmpfile)
      end
      #
      ok {tmpfile}.file_exist?
    end

  end

end
```

* `at_end()` can be called multiple times in a spec.
* Registered blocks are invoked in reverse order at end of test case.
* Registered blocks of `at_end()` are invoked prior to block of `after()`.
* If something error raised in `at_end()`, test script execution will be
  stopped instantly.


### Named Fixtures

`fixture() { ... }` in topic or scope block defines fixture builder,
and `fixture()` in spec block returns fixture data.

test/example23_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  fixture :alice do               # define fixture
    {name: "Alice"}
  end

  fixture :bob do                 # define fixture
    {name: "Bob"}
  end

  topic "Named fixture" do

    spec "example spec" do
      alice = fixture(:alice)     # create fixture object
      bob   = fixture(:bob)       # create fixture object
      ok {alice[:name]} == "Alice"
      ok {bob[:name]}   == "Bob"
    end

  end

end
```

Fixture block can have parameters.

test/example24_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  fixture :team do |mem1, mem2|   # define fixture with block params
    {members: [mem1, mem2]}
  end

  topic "Named fixture with args" do

    spec "example spec" do
      alice = {name: "Alice"}
      bob   = {name: "Bob"}
      team = fixture(:team, alice, bob)  # create fixture with args
      ok {team[:members][0][:name]} == "Alice"
      ok {team[:members][1][:name]} == "Bob"
    end

  end

end
```

* Fixture builders can be defined in `topic()` block as well as `Oktest.scope()` block.
* If fixture requires clean-up operation, call `at_end()` in `fixture()` block.

```ruby
  fixture :tmpfile do
    tmpfile = "tmp#{rand().to_s[2..5]}.txt"
    File.write(tmpfile, "foobar\n", encoding: 'utf-8')
    at_end { File.unlink(tmpfile) if File.exist?(tmpfile) }   # !!!!!
    tmpfile
  end
```


### Fixture Injection

Block parameters of `spec()` or `fixture()` represents fixture name, and
Oktest.rb injects fixture objects into that parameters automatically.

test/example25_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  fixture :alice do               # define fixture
    {name: "Alice"}
  end

  fixture :bob do                 # define fixture
    {name: "Bob"}
  end

  fixture :team do |alice, bob|   # !!! fixture injection !!!
    {members: [alice, bob]}
  end

  topic "Fixture injection" do

    spec "example spec" do
      |alice, bob, team|          # !!! fixture injection !!!
      ok {alice[:name]} == "Alice"
      ok {bob[:name]}   == "Bob"
      #
      ok {team[:members]}.length(2)
      ok {team[:members][0]} == {name: "Alice"}
      ok {team[:members][1]} == {name: "Bob"}
    end

  end

end
```

<!--
* Special fixture name `this_topic` represents the first argument of `topic()`.
* Special fixture name `this_spec` represents the description of `spec()`.
-->


### `fixture:` keyword argument

`scope()` takes `fixture:` keyword argument which overwrites fixture value.

test/example26_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  fixture :user do |uname, uid: 101|   # `uid` is keyword param
    {name: uname, id: uid}
  end

  fixture :uname do
    "Alice"
  end

  ## keyword argument `fixture:` overwrites fixture values
  spec "example", fixture: {uname: "Bob", uid: 201} do   # !!!!!
    |user|
    ok {user[:name]} == "Bob"    # != "Alice"
    ok {user[:id]}   == 201      # != 101
  end

end
```


### Global Scope

It is a good idea to separate common fixtures into dedicated file.
In this case, use `Oktest.global_scope()` instead of `Oktest.scope()`.

test/example27_test.rb:

```ruby
require 'oktest'

## define common fixtures in global scope
Oktest.global_scope do     # !!!!!

  fixture :alice do
    {name: "Alice"}
  end

  fixture :bob do
    {name: "Bob"}
  end

  fixture :team do |alice, bob|
    {members: [alice, bob]}
  end

end
```



## Helpers


### `capture_sio()`

`capture_sio()` captures standard I/O.

test/example31_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "Capturing" do

    spec "example spec" do
      data = nil
      sout, serr = capture_sio("blabla") do            # !!!!!
        data = $stdin.read()     # read from stdin
        puts "fooo"              # write into stdout
        $stderr.puts "baaa"      # write into stderr
      end
      ok {data} == "blabla"
      ok {sout} == "fooo\n"
      ok {serr} == "baaa\n"
    end

  end

end
```

* The first argument of `capture_sio()` represents data from `$stdin`.
  If it is not necessary, you can omit it like `caputre_sio() do ... end`.
* If you need `$stdin.tty? == true` and `$stdout.tty? == true`,
  call `capture_sio(tty: true) do ... end`.


### `dummy_file()`

`dummy_file()` creates a dummy file temporarily.

test/example32_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "dummy_file()" do

    spec "usage #1: without block" do
      tmpfile = dummy_file("_tmp_file.txt", "blablabla")    # !!!!!
      ok {tmpfile} == "_tmp_file.txt"
      ok {tmpfile}.file_exist?
      ## dummy file will be removed automatically at end of spec block.
    end

    spec "usage #2: with block" do
      result = dummy_file("_tmp_file.txt", "blabla") do |tmpfile|  # !!!!!
        ok {tmpfile} == "_tmp_file.txt"
        ok {tmpfile}.file_exist?
        ## dummy file will be removed automatically at end of this block.
        ## last value of block will be the return value of dummy_file().
        1234
      end
      ok {result} == 1234
      ok {"_tmp_file.txt"}.not_exist?
    end

  end

end
```

* If the first argument of `dummy_file()` is nil, then it generates temporary file name automatically.


### `dummy_dir()`

`dummy_dir()` creates a dummy directory temporarily.

test/example33_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "dummy_dir()" do

    spec "usage #1: without block" do
      tmpdir = dummy_dir("_tmp_dir")               # !!!!!
      ok {tmpdir} == "_tmp_dir"
      ok {tmpdir}.dir_exist?
      ## dummy directory will be removed automatically at end of spec block
      ## even if it contais other files or directories.
    end

    spec "usage #2: with block" do
      result = dummy_dir("_tmp_dir") do |tmpdir|   # !!!!!
        ok {tmpdir} == "_tmp_dir"
        ok {tmpdir}.dir_exist?
        ## dummy directory will be removed automatically at end of this block
        ## even if it contais other files or directories.
        ## last value of block will be the return value of dummy_dir().
        2345
      end
      ok {result} == 2345
      ok {"_tmp_dir"}.not_exist?
    end

  end

end
```

* If the first argument of `dummy_dir()` is nil, then it generates temorary directory name automatically.


### `dummy_values()`

`dummy_values()` changes hash values temporarily.

test/example34_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "dummy_values()" do

    spec "usage #1: without block" do
      hashobj = {:a=>1, 'b'=>2, :c=>3}   # `:x` is not a key
      ret = dummy_values(hashobj, :a=>100, 'b'=>200, :x=>900)  # !!!!!
      ok {hashobj[:a]} == 100
      ok {hashobj['b']} == 200
      ok {hashobj[:c]} == 3
      ok {hashobj[:x]} == 900
      ok {ret} == {:a=>100, 'b'=>200, :x=>900}
      ## values of hash object are recovered at end of spec block.
    end

    spec "usage #2: with block" do
      hashobj = {:a=>1, 'b'=>2, :c=>3}   # `:x` is not a key
      ret = dummy_values(hashobj, :a=>100, 'b'=>200, :x=>900) do |keyvals| # !!!!!
        ok {hashobj[:a]} == 100
        ok {hashobj['b']} == 200
        ok {hashobj[:c]} == 3
        ok {hashobj[:x]} == 900
        ok {keyvals} == {:a=>100, 'b'=>200, :x=>900}
        ## values of hash object are recovered at end of this block.
        ## last value of block will be the return value of dummy_values().
        3456
      end
      ok {hashobj[:a]} == 1
      ok {hashobj['b']} == 2
      ok {hashobj[:c]} == 3
      not_ok {hashobj}.key?(:x)   # because `:x` was not a key
      ok {ret} == 3456
    end

  end

end
```

* `dummy_values()` is very useful to change envirnment variables temporarily,
   such as `dummy_values(ENV, 'LANG'=>'en_US.UTF-8')`.


### `dummy_attrs()`

`dummy_attrs()` changes object attribute values temporarily.

test/example35_test.rb:

```ruby
require 'oktest'

class User
  def initialize(id, name)
    @id   = id
    @name = name
  end
  attr_accessor :id, :name
end

Oktest.scope do

  topic "dummy_attrs()" do

    spec "usage #1: without block" do
      user = User.new(123, "alice")
      ok {user.id} == 123
      ok {user.name} == "alice"
      ret = dummy_attrs(user, :id=>999, :name=>"bob")   # !!!!!
      ok {user.id} == 999
      ok {user.name} == "bob"
      ok {ret} == {:id=>999, :name=>"bob"}
      ## attribute values are recovered at end of spec block.
    end

    spec "usage #2: with block" do
      user = User.new(123, "alice")
      ok {user.id} == 123
      ok {user.name} == "alice"
      ret = dummy_attrs(user, :id=>999, :name=>"bob") do |keyvals|  # !!!!!
        ok {user.id} == 999
        ok {user.name} == "bob"
        ok {keyvals} == {:id=>999, :name=>"bob"}
        ## attribute values are recovered at end of this block.
        ## last value of block will be the return value of dummy_attrs().
        4567
      end
      ok {user.id} == 123
      ok {user.name} == "alice"
      ok {ret} == 4567
    end

  end

end
```


### `dummy_ivars()`

`dummy_ivars()` changes instance variables in object with dummy values temporarily.

test/example36_test.rb:

```ruby
require 'oktest'

class User
  def initialize(id, name)
    @id   = id
    @name = name
  end
  attr_reader :id, :name    # setter, not accessor
end

Oktest.scope do

  topic "dummy_attrs()" do

    spec "usage #1: without block" do
      user = User.new(123, "alice")
      ok {user.id} == 123
      ok {user.name} == "alice"
      ret = dummy_ivars(user, :id=>999, :name=>"bob")   # !!!!!
      ok {user.id} == 999
      ok {user.name} == "bob"
      ok {ret} == {:id=>999, :name=>"bob"}
      ## attribute values are recovered at end of spec block.
    end

    spec "usage #2: with block" do
      user = User.new(123, "alice")
      ok {user.id} == 123
      ok {user.name} == "alice"
      ret = dummy_ivars(user, :id=>999, :name=>"bob") do |keyvals|  # !!!!!
        ok {user.id} == 999
        ok {user.name} == "bob"
        ok {keyvals} == {:id=>999, :name=>"bob"}
        ## attribute values are recovered at end of this block.
        ## last value of block will be the return value of dummy_attrs().
        6789
      end
      ok {user.id} == 123
      ok {user.name} == "alice"
      ok {ret} == 6789
    end

  end

end
```


### `recorder()`

`recorder()` returns `Benry::Recorder` object.
See [Benry::Recorder README](https://github.com/kwatch/benry-ruby/blob/ruby/benry-recorder/README.md)
for detals.

test/example37_test.rb:

```ruby
require 'oktest'

class Calc
  def total(*nums)
    t = 0; nums.each {|n| t += n }   # or: nums.sum()
    return t
  end
  def average(*nums)
    return total(*nums).to_f / nums.length
  end
end


Oktest.scope do

  topic 'recorder()' do

    spec "records method calls." do
      ## target object
      calc = Calc.new
      ## record method call
      rec = recorder()               # !!!!!
      rec.record_method(calc, :total)
      ## method call
      v = calc.average(1, 2, 3, 4)   # calc.average() calls calc.total() internally
      p v                   #=> 2.5
      ## show method call info
      p rec.length          #=> 1
      p rec[0].obj == calc  #=> true
      p rec[0].name         #=> :total
      p rec[0].args         #=> [1, 2, 3, 4]
      p rec[0].ret          #=> 2.5
    end

    spec "defines fake methods." do
      ## target object
      calc = Calc.new
      ## define fake methods
      rec = recorder()                 # !!!!!
      rec.fake_method(calc, :total=>20, :average=>5.5)
      ## call fake methods
      v1 = calc.total(1, 2, 3)         # fake method returns dummy value
      p v1                  #=> 20
      v2 = calc.average(1, 2, 'a'=>3)  # fake methods accepts any args
      p v2                  #=> 5.5
      ## show method call info
      puts rec.inspect
        #=> 0: #<Calc:0x00007fdb5482c968>.total(1, 2, 3) #=> 20
        #   1: #<Calc:0x00007fdb5482c968>.average(1, 2, {"a"=>3}) #=> 5.5
    end

  end

end
```


### `partial_regexp()`

`partial_regexp()` can embed regexp pattern into string, and compile it into Regexp object. This is very useful to validate multiline string with regexp.

Assume that you are testing the following function `f1()`. It generates multiline string containing date and random string.

```ruby
def f1()
  today  = Date.today.to_s                  # ex: '2021-12-31'
  secret = Random.bytes(8).unpack('H*')[0]  # ex: "cd0b260ac728eda5"
  return <<END
* [config.date]   #{today}
* [config.secret] #{secret}
END
end
```ruby

To test `f1()`, you may write the following test code.
As you can see, expected regexp literal is complicated.

```ruby
  topic 'f1()' do
    spec "generates multiline string." do
      expected = /\A\* \[config\.date\]   \d\d\d\d-\d\d-\d\d\n\* \[config\.secret\] [0-9a-f]+\n/
      ok {f1()} =~ expected
    end
  end
```

[`x` option](https://ruby-doc.org/core-2.7.0/Regexp.html#class-Regexp-label-Free-Spacing+Mode+and+Comments) of regexp (such as `/.../x`) allows you to write regexp literal in multiline format.
But you have to escape metachars (`*`, `.`, `[]`, and white space).

```ruby
  topic 'f1()' do
    spec "generates multiline string." do
      expected = /\A
\*\ \[config\.date\]\ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[config\.secret\]\ [0-9a-f]+\n
\z/x      # !!!!!
      ok {f1()} =~ expected
    end
  end
```

In such case, `partial_regexp()` is very useful. It compiles string into Regexp object.
Using `partial_regexp()`, you can write expected regexp very easily.

```ruby
  topic 'f1()' do
    spec "generates multiline string." do
      # - Regexp can be in `{== ==}`.
      # - Other text part is escaped by `Regexp.escape()`.
      expected = partial_regexp <<'END'      # !!!!!
* [config.date]   {== \d\d\d\d-\d\d-\d\d ==}
* [config.secret] {== [0-9a-f]+ ==}
END
      ok {f1()} =~ expected
      ## above is equivarent to:
      #expected = /\A
      #\*\ \[config\.date\]\ \ \ \d\d\d\d-\d\d-\d\d\n
      #\*\ \[config\.secret\]\ [0-9a-f]+\n
      #\z/x      # !!!!!
      #ok {f1()} =~ expected
    end
  end
```

`partial_regexp()` takes 4 arguments.

```ruby
def partial_regexp(pattern, begin_='\A', end_='\z', mark='{== ==}')
```

`partial_regexp()` adds `\A` and `\z` automatically.
If you want not to add them, pass empty string or nil as 2nd and 3rd argument, like this:

```ruby
partial_regexp <<-'END', '', ''    # !!!!!
...
END
```

If you want to change embed mark, specify 4th argument, like this:

```ruby
partial_regexp <<-'END', '\A', '\z', '%%(.*?)%%'    # !!!!!
* [config.date]   %% \d\d\d\d-\d\d-\d\d %%
* [config.secret] %% [0-9a-f]+ %%
END
```

Oktest.rb provides `partial_regexp!()`, too.
Difference between `partial_regexp()` and `partial_regexp!()` is the result of `#inspect()`.
This is imortant only when assertion failed and error message reported.
You can use whichever you like.

```ruby
r1 = partial_regexp <<-'END'
* [config.date]   {== \d\d\d\d-\d\d-\d\d ==}
* [config.secret] {== [0-9a-f]+ ==}
END
p r1
   #=> /\A
   #   \*\ \[config\.date\]\ \ \ \d\d\d\d-\d\d-\d\d\n
   #   \*\ \[config\.secret\]\ [0-9a-f]+\n
   #   \z/x

r2 = partial_regexp! <<-'END'                   # !!!!!
* [config.date]   {== \d\d\d\d-\d\d-\d\d ==}
* [config.secret] {== [0-9a-f]+ ==}
END
p r2
   #=> partial_regexp(<<PREXP, '\A', '\z')
   #   * [config.date]   {== \d\d\d\d-\d\d-\d\d ==}
   #   * [config.secret] {== [0-9a-f]+ ==}
   #   PREXP
```


## JSON Matcher

Oktest.rb provides easy way to assert JSON data.
This is very convenient feature, but don't abuse it.


### Simple Example

<!--
test/example41_test.rb:
-->
```ruby
require 'oktest'
require 'set'                               # !!!!!

Oktest.scope do
  topic 'JSON Example' do

    spec "simple example" do
      actual = {
        "name":     "Alice",
        "id":       1001,
        "age":      18,
        "email":    "alice@example.com",
        "gender":   "F",
        "deleted":  false,
        "tags":     ["aaa", "bbb", "ccc"],
       #"twitter":  "@alice",
      }
      ## assertion
      ok {JSON(actual)} === {               # requires `JSON()` and `===`
        "name":     "Alice",                # scalar value
        "id":       1000..9999,             # range object
        "age":      Integer,                # class object
        "email":    /^\w+@example\.com$/,   # regexp
        "gender":   Set.new(["M", "F"]),    # Set object ("M" or "F")
        "deleted":  Set.new([true, false]), # boolean (true or false)
        "tags":     [/^\w+$/].each,         # Enumerator object (!= Array obj)
        "twitter?": /^@\w+$/,               # key 'xxx?' means optional value
      }
    end

  end
end
```

(Note: Ruby 2.4 or older doesn't have `Set#===()`, so above code will occur error
 in Ruby 2.4 or older. Please add the folllowing hack in your test script.)

```ruby
require 'set'
unless Set.instance_methods(false).include?(:===)  # for Ruby 2.4 or older
  class Set; alias === include?; end
end
```

Notice that `Enumerator` has different meaning from `Array` in JSON matcher.

```ruby
  actual = {"tags": ["foo", "bar", "baz"]}

  ## Array
  ok {JSON(actual)} == {"tags": ["foo", "bar", "baz"]}

  ## Enumerator
  ok {JSON(actual)} == {"tags": [/^\w+$/].each}
```


### Nested Example

<!--
test/example42_test.rb:
-->
```ruby
require 'oktest'
require 'set'                            # !!!!!

Oktest.scope do
  topic 'JSON Example' do

    spec "nested example" do
      actual = {
        "teams": [
          {
            "team": "Section 9",
            "members": [
              {"id": 2500, "name": "Aramaki", "gender": "M"},
              {"id": 2501, "name": "Motoko" , "gender": "F"},
              {"id": 2502, "name": "Batou"  , "gender": "M"},
            ],
            "leader": "Aramaki",
          },
          {
            "team": "SOS Brigade",
            "members": [
              {"id": 1001, "name": "Haruhi", "gender": "F"},
              {"id": 1002, "name": "Mikuru", "gender": "F"},
              {"id": 1003, "name": "Yuki"  , "gender": "F"},
              {"id": 1004, "name": "Itsuki", "gender": "M"},
              {"id": 1005, "name": "Kyon"  , "gender": "M"},
            ],
          },
        ],
      }
      ## assertion
      ok {JSON(actual)} === {            # requires `JSON()` and `===`
        "teams": [
          {
            "team": String,
            "members": [
              {"id": 1000..9999, "name": String, "gender": Set.new(["M", "F"])}
            ].each,                     # Enumerator object (!= Array obj)
            "leader?": String,           # key 'xxx?' means optional value
          }
        ].each,                          # Enumerator object (!= Array obj)
      }
    end

  end
end
```


### Complex Example

* `OR(x, y, z)` matches to `x`, `y`, or `z`.
* `AND(x, y, z)` matches to `x`, `y`, and `z`.
* Key `"*"` matches to any key of hash object.
* `Any()` matches to anything.

<!--
test/example43_test.rb:
-->
```ruby
require 'oktest'
require 'set'

Oktest.scope do
  topic 'JSON Example' do

    spec "OR() example" do
      ok {JSON({"val": "123"})} === {"val": OR(String, Integer)}    # OR()
      ok {JSON({"val":  123 })} === {"val": OR(String, Integer)}    # OR()
    end

    spec "AND() example" do
      ok {JSON({"val": "123"})} === {"val": AND(String, /^\d+$/)}   # AND()
      ok {JSON({"val":  123 })} === {"val": AND(Integer, 1..1000)}  # AND()
    end

    spec "`*` and `ANY` example" do
      ok {JSON({"name": "Bob", "age": 20})} === {"*": Any()}    # '*' and Any()
    end

    spec "complex exapmle" do
      actual = {
        "item":   "awesome item",
        "colors": ["red", "#cceeff", "green", "#fff"],
        "memo":   "this is awesome.",
        "url":    "https://example.com/awesome",
      }
      ## assertion
      color_names = ["red", "blue", "green", "white", "black"]
      color_pat   = /^\#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$/
      ok {JSON(actual)} === {
        "colors": [
          AND(String, OR(Set.new(color_names), color_pat)),   # AND() and OR()
        ].each,
        "*": Any(),             # match to any key (`"*"`) and value (`ANY`)
      }
    end

  end
end
```

(Note: `/^\d+$/` implies String value, and `1..100` implies Integer value.)

```ruby
## No need to write:
##   ok {JSON{...}} === {"val": AND(String, /^\d+$/)}
##   ok {JSON{...}} === {"val": AND(Integer, 1..100)}
ok {JSON({"val": "A"})} === {"val": /^\d+$/}   # implies String value
ok {JSON({"val": 99 })} === {"val": 1..100}    # implies Integer value
```


### Helper Methods for JSON Matcher

Oktest.rb provides some helper methods and objects:

* `Enum(x, y, z)` is almost same as `Set.new([x, y, z])`.
* `Bool()` is same as `Enum(true, false)`.
* `Length(3)` matches to length 3, and `Length(1..3)` matches to length 1..3.

<!--
test/example44_test.rb:
-->
```ruby
  actual = {"gender": "M", "deleted": false, "code": "ABCD1234"}
  ok {JSON(actual)} == {
    "gender":  Enum("M", "F"),        # same as Set.new(["M", "F"])
    "deleted": Bool(),                # same as Enum(true, false)
    "code":    Length(6..10),         # code length should be 6..10
  }
```



## Tips


### `ok {}` in MiniTest

If you want to use `ok {actual} == expected` style assertion in MiniTest,
install `minitest-ok` gem instead of `otest` gem.

test/example51_test.rb:

```ruby
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'      # !!!!!

describe 'MiniTest::Ok' do

  it "helps to write assertions" do
    ok {1+1} == 2          # !!!!!
  end

end
```

See [minitest-ok README](https://github.com/kwatch/minitest-ok) for details.


### Testing Rack Application

`rack-test_app` gem will help you to test Rack application very well.

test/example52_test.rb:

```ruby
require 'rack'
require 'rack/lint'
require 'rack/test_app'      # !!!!!
require 'oktest'

app = proc {|env|            # sample Rack application
  text = '{"status":"OK"}'
  headers = {"Content-Type"   => "application/json",
             "Content-Length" => text.bytesize.to_s}
  [200, headers, [text]]
}

http = Rack::TestApp.wrap(Rack::Lint.new(app))   # wrap Rack app

Oktest.scope do

+ topic("GET /api/hello") do

  - spec("returns JSON data.") do
      response = http.GET("/api/hello")        # call Rack app
      ok {response.status}       == 200
      ok {response.content_type} == "application/json"
      ok {response.body_json}    == {"status"=>"OK"}
    end

  end

end
```

Defining helper methods per topic may help you.

```ruby
$http = http                                   # !!!!

Oktest.scope do

+ topic("GET /api/hello") do

    def api_call(**kwargs)                     # !!!!!
      $http.GET("/api/hello", **kwargs)        # !!!!!
    end                                        # !!!!!

  - spec("returns JSON data.") do
      response = api_call()                    # !!!!!
      ok {response.status}       == 200
      ok {response.content_type} == "application/json"
      ok {response.body_json}    == {"status"=>"OK"}
    end

  end

+ topic("POST /api/hello") do

    def api_call(**kwargs)                     # !!!!!
      $http.POST("/api/hello", **kwargs)       # !!!!!
    end                                        # !!!!!

    ....

  end

end
```


### Environment Variale `$OKTEST_RB`

You can set default command-line option to environment variale `$OKTEST_RB`.
For examle, you can specify default reporting style with `$OKTEST_RB`.

```terminal
### change default reporting style to plain-style.
$ export OKTEST_RB="-s plain"                  # !!!!!

### run test script in plain-style reporting without '-s' option.
$ ruby test/foo_test.rb
```


### Traverser Class

Oktest.rb provides `Traverser` class which implements Visitor pattern.

test/example54_test.rb:

```ruby
require 'oktest'

Oktest.scope do
+ topic('Example Topic') do
  - spec("sample #1") do ok {1+1} == 2 end
  - spec("sample #2") do ok {1-1} == 0 end
  + case_when('some condition...') do
    - spec("sample #3") do ok {1*1} == 1 end
    end
  + case_else() do
    - spec("sample #4") do ok {1/1} == 1 end
    end
  end
end

## custom traverser class
class MyTraverser < Oktest::Traverser  # !!!!!
  def on_scope(filename, tag, depth)   # !!!!!
    print "  " * depth
    print "# scope: #{filename}"
    print " (tag: #{tag})" if tag
    print "\n"
    yield                              # should yield !!!
  end
  def on_topic(target, tag, depth)     # !!!!!
    print "  " * depth
    print "+ topic: #{target}"
    print " (tag: #{tag})" if tag
    print "\n"
    yield                              # should yield !!!
  end
  def on_case(cond, tag, depth)        # !!!!!
    print "  " * depth
    print "+ case: #{cond}"
    print " (tag: #{tag})" if tag
    print "\n"
    yield                              # should yield !!!
  end
  def on_spec(desc, tag, depth)        # !!!!!
    print "  " * depth
    print "- spec: #{desc}"
    print " (tag: #{tag})" if tag
    print "\n"
  end
end

## run custom traverser
Oktest::Config.auto_run = false    # stop running test cases
MyTraverser.new.start()
```

Result:

```terminal
$ ruby test/example54_test.rb
# scope: test/example54_test.rb
  + topic: Example Topic
    - spec: sample #1
    - spec: sample #2
    + case: When some condition...
      - spec: sample #3
    + case: Else
      - spec: sample #4
```


### Benchmarks

Oktest.rb gem file contains benchmark script.
It shows that Oktest.rb runs more than three times faster than RSpec.

```terminal
$ gem install oktest        # ver 1.2.0
$ gem install rspec         # ver 3.10.0
$ gem install minitest      # ver 5.14.4
$ gem install test-unit     # ver 3.4.4

$ cp -pr $GEM_HOME/gems/oktest-1.2.0/benchmark .
$ cd benchmark/
$ rake -T
$ ruby --version
ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin18]

$ rake benchmark:all
```

Example result:

```
==================== oktest ====================
oktest -sq run_all.rb

## total:100000 (pass:100000, fail:0, error:0, skip:0, todo:0) in 2.36s

        6.815 real        6.511 user        0.257 sys

==================== oktest:faster ====================
oktest -sq --faster run_all.rb

## total:100000 (pass:100000, fail:0, error:0, skip:0, todo:0) in 2.01s

        6.401 real        6.123 user        0.240 sys

==================== rspec ====================
rspec run_all.rb | tail -4

Finished in 15.27 seconds (files took 16.08 seconds to load)
100000 examples, 0 failures


        32.062 real        27.778 user        4.383 sys

==================== minitest ====================
ruby run_all.rb | tail -4

Finished in 5.281425s, 18934.2838 runs/s, 37868.5677 assertions/s.

100000 runs, 200000 assertions, 0 failures, 0 errors, 0 skips

        9.140 real        8.657 user        0.705 sys

==================== testunit ====================
ruby run_all.rb | tail -5
-------------------------------------------------------------------------------
100000 tests, 200000 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
100% passed
-------------------------------------------------------------------------------
7775.59 tests/s, 15551.18 assertions/s

        19.580 real        19.020 user        0.885 sys
```

Summary:

```
Oktest:              6.815 real     6.511 user     0.257 sys
Oktest (--fast):     6.401 real     6.123 user     0.240 sys
RSpec:              32.062 real    27.778 user     4.383 sys
MiniTest:            9.140 real     8.657 user     0.705 sys
Test::Unit:         19.580 real    19.020 user     0.885 sys
```


### `--faster` Option

If you are working in very larget project and you want to run test scripts
as fast as possible, try `--faster` option of `oktest` command.

```terminal
$ oktest -s quiet --faster test/        ## only for very large project
```

Or set `Oktest::Config.ok_location = false` in your test script.

```ruby
require 'oktest'
Oktest::Config.ok_location = false      ## only for very large project
```



## Change Log

See [CHANGES.md](https://github.com/kwatch/oktest/blob/ruby/ruby/CHANGES.md).



## License and Copyright

* $License: MIT License $
* $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
