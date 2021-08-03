<!-- coding: utf-8 -->
# Oktest.rb README


Oktest.rb is a new-style testing library for Ruby.

* `ok {actual} == expected` style assertion.
* **Fixture injection** inspired by dependency injection.
* Structured test specifications like RSpec.
* Filtering testcases by pattern or tags.
* Blue/red color instead of green/red for accesability.

```ruby
### Oktest                           ### Test::Unit
require 'oktest'                     #  require 'test/unit'
                                     #
Oketst.scope do                      #
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
      pr = proc { .... }             #      ex = assert_raise(Error) { .... }
      ok {pr}.raise?(Error, "mesg")  #      assert ex.message, "mesg"
      ex = pr.exception              #
    end                              #    end
                                     #
  end                                #  end
                                     #
end                                  #
```

Oktest.rb requires Ruby 2.3 or later.


## Table of Contents

<!-- TOC -->

  * <a href="#quick-tutorial">Quick Tutorial</a>
    * <a href="#install">Install</a>
    * <a href="#basic-example">Basic Example</a>
    * <a href="#assertion-failure-and-error">Assertion Failure, and Error</a>
    * <a href="#skip-and-todo">Skip, and Todo</a>
    * <a href="#reporting-style">Reporting Style</a>
    * <a href="#run-all-test-scripts-under-directory">Run All Test Scripts Under Directory</a>
    * <a href="#tag-and-filtering">Tag and Filtering</a>
    * <a href="#case_when-and-case_else"><code>case_when</code> and <code>case_else</code></a>
    * <a href="#generate-test-code-skeleton">Generate Test Code Skeleton</a>
    * <a href="#optional-unary-operators">Optional: Unary Operators</a>
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
    * <a href="#fixture-injection">Fixture Injection</a>
    * <a href="#global-scope">Global Scope</a>
  * <a href="#helpers">Helpers</a>
    * <a href="#capture_sio"><code>capture_sio()</code></a>
    * <a href="#dummy_file"><code>dummy_file()</code></a>
    * <a href="#dummy_dir"><code>dummy_dir()</code></a>
    * <a href="#dummy_values"><code>dummy_values()</code></a>
    * <a href="#dummy_attrs"><code>dummy_attrs()</code></a>
    * <a href="#dummy_ivars"><code>dummy_ivars()</code></a>
    * <a href="#recorder"><code>recorder()</code></a>
  * <a href="#tips">Tips</a>
    * <a href="#ok--in-minitest"><code>ok {}</code> in MiniTest</a>
    * <a href="#testing-rack-application">Testing Rack Application</a>
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
$ vim test/example_test.rb
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
$ oketst test/example01_test.rb   # or: ruby test/example01_test.rb
* Hello
  * #hello()
    - [pass] returns greeting message.
    - [pass] accepts user name.
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```


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
* other examples
  - [Fail] example of assertion failure
  - [ERROR] example of something error
----------------------------------------------------------------------
[Fail] other examples > example of assertion failure
    tmp/test/example02_test.rb:9:in `block (3 levels) in <main>'
        ok {1+1} == 0     # FAIL
$<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 0
----------------------------------------------------------------------
[ERROR] other examples > example of something error
    tmp/test/example02_test.rb:13:in `block (3 levels) in <main>'
        x = foobar        # NameError
NameError: undefined local variable or method `foobar' for #<#<Class:...>:...>
----------------------------------------------------------------------
## total:2 (pass:0, fail:1, error:1, skip:0, todo:0) in 0.000s
```


### Skip, and Todo

test/example03_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic 'other examples' do

    spec "example of skip" do
      skip_when RUBY_VERSION < "3.0", "requires Ruby3"
      ok {1+1} == 2
    end

    spec "example of todo"    # no block means TODO

  end

end
```

Result:

```terminal
$ oktest test/example03_test.rb   # or: ruby test/example03_test.rb
* other examples
  - [Skip] example of skip (reason: requires Ruby3)
  - [TODO] example of todo
## total:2 (pass:0, fail:0, error:0, skip:1, todo:1) in 0.000s
```


### Reporting Style

Verbose mode (default):

```terminal
$ oktest test/example01_test.rb -s verbose  # or -sv
* Hello
  * #hello()
    - [pass] returns greeting message.
    - [pass] accepts user name.
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Simple mode:

```terminal
$ oktest test/example01_test.rb -s simple   # or -ss
test/example01_test.rb: ..
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```

Plain mode:

```terminal
$ oktest test/example01_test.rb -s simple   # or -ss
..
## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```


### Run All Test Scripts Under Directory

How to run test scripts under `test` directory:

```terminal
$ ls test
example01_test.rb       example02_test.rb       example03_test.rb

$ oktest -s simple test  # or: ruby -r oktest -e 'Oktest.main' -- test -s simple
tmp/test/example01_test.rb: ..
tmp/test/example02_test.rb: fE
----------------------------------------------------------------------
[Fail] other examples > example of assertion failure
    tmp/test/example02_test.rb:9:in `block (3 levels) in <top (required)>'
        ok {1+1} == 0     # FAIL
    -e:1:in `<main>'
$<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 0
----------------------------------------------------------------------
[ERROR] other examples > example of something error
    tmp/test/example02_test.rb:13:in `block (3 levels) in <top (required)>'
        x = foobar        # NameError
    -e:1:in `<main>'
NameError: undefined local variable or method `foobar' for #<#<Class:...>:...>
----------------------------------------------------------------------
tmp/test/example03_test.rb: st
## total:6 (pass:2, fail:1, error:1, skip:1, todo:1) in 0.000s
```

Test script filename should be `test_xxx.rb` or `xxx_test.rb`
(not `test-xxx.rb` nor `xxx-test.rb`).


### Tag and Filtering

`topic()` and `spec()` accepts tag name, for example 'obsolete' or 'experimental'.

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

It is possible to filter topics and specs by tag name (pattern).

```terminal
$ oktest -F tag=exp         tests/     # filter by tag name
$ oktest -F tag='*exp*'     tests/     # filter by tag name pattern
$ oktest -F tag='{exp,old}' tests/     # filter by multiple tag names
```

It is also possible to filter topics or specs by name.
Pattern (!= regular expression) supports `*`, `?`, `[]`, and `{}`.

```terminal
$ oktest -F topic='*Integer*' test/    # filter topics by pattern
$ oktest -F spec='*#[1-3]'    test/    # filter specs by pattern
```

If you need negative filter, use `!=` instead of `=`.

```terminal
$ oktest -F spec!='*#5'      tests/    # exclude spec 'example #5'
$ oktest -F tag!='{exp,old}' tests/    # exclude tag='exp' or tag='old'
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


### Generate Test Code Skeleton

`oktest -g` (or `oktest --generate`) generates test code skeleton from ruby file.
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
$ oktest -g hello.rb > test/hello_test.rb
```

test/hello_test.rb:

```ruby
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello' do

      spec "default name is 'world'."

      spec "returns greeting message."

    end


  end # Hello


end
```


### Optional: Unary Operators

`topic()` accepts unary `+` operator and `spec()` accepts unary `-` operator.
This makes test scripts more readable.

<!--
test/example06_test.rb:
-->

```ruby
require 'oktest'

Oktest.scope do

+ topic 'example' do            # unary `+` operator

  + topic 'example' do          # unary `+` operator

    - spec "1+1 is 2." do       # unary `-` operator
        ok {1+1} == 2
      end

    - spec "1*1 is 1." do       # unary `-` operator
        ok {1*1} == 1
      end

    end

  end

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
      s = hello()               # call method in spec block
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

+ topic "Outer" do

  + topic "Middle" do

      def hello()              # define method in topic block
        return "Hello!"
      end

    + topic "Inner" do

      - spec "inner spec" do
          s = hello()          # OK: call method defined in parent topic
          ok {s} == "Hello!"
        end

      end

    end

  - spec "outer spec" do
      s = hello()              # ERROR: call method defined in child topic
      ok {x} == "Hello!"
    end

  end

end
```



## Assertions


### Basic Assertions

In the following example, `a` means actual value and `e` means expected value.

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
ok {a}.include?(e)       # fail unless a.include?(e)
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

It is possible to chan method call of `.attr()` and `.keyval()`.

```ruby
ok {a}.attr(:name1, 'val1').attr(:name2, 'val2').attr(:name3, 'val3')
ok {a}.keyval(:key1, 'val1').keyval(:key2, 'val2').keyval(:key3, 'val3')
```


### Predicate Assertions

`ok {}` handles predicate methods (such as `.nil?`, `.empty?`, or `.key?`) automatically.

```ruby
ok {a}.nil?              # same as ok {a.nil?} == true
ok {a}.empty?            # same as ok {a.empty?} == true
ok {a}.key?(e)           # same as ok {a.key?(e)} == true
ok {a}.is_a?(e)          # same as ok {a.is_a?(e)} == true
ok {a}.between?(x, y)    # same as ok {a.between?(x, y)} == true
```

`Pathname()` is a good example of predicate methods.
See [pathname.rb](https://ruby-doc.org/stdlib-2.7.0/libdoc/pathname/rdoc/Pathname.html)
document for details about `Pathname()`.

```ruby
require 'pathname'      # !!!!!

ok {Pathname(a)}.owned?      # same as ok {Pathname(a).owned?} == true
ok {Pathname(a)}.readable?   # same as ok {Pathname(a).readable?} == true
ok {Pathname(a)}.writable?   # same as ok {Pathname(a).writable?} == true
ok {Pathname(a)}.absolute?   # same as ok {Pathname(a).absolute?} == true
ok {Pathname(a)}.relative?   # same as ok {Pathname(a).relative?} == true
```


### Negative Assertion

```ruby
not_ok {a} == e          # fail if a == e
ok {a}.NOT == e          # fail if a == e

not_ok {a}.file_exist?   # fail if File.file?(a)
ok {a}.NOT.file_exist?   # fail if File.file?(a)
```


### Exception Assertion

If you want to assert whether exception raised or not:

```ruby
pr = proc do
  "abc".len()    # NoMethodError
end
ok {pr}.raise?(NoMethodError)
ok {pr}.raise?(NoMethodError, "undefined method `len' for \"abc\":String")
ok {pr}.raise?(NoMethodError, /^undefined method `len'/)

## get exception object
ok {pr.exception.class} == NoMethodError
ok {pr.exception.message} == "undefined method `len' for \"abc\":String"

## if you want to assert that procedure NOT raise exception...
not_ok {pr}.raise?(NoMethodError)   # only exception class, no errmsg
ok {pr}.NOT.raise?(NoMethodError)   # only exception class, no errmsg
```


### Custom Assertion

How to define custom assertion:

test/example11_test.rb:

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

test/example21_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  topic "Fixture example" do

    before do       # equivarent to setUp()
      puts "** before() called"
    end

    after do        # equivarent to tearDown()
      puts "** after() called"
    end

    before_all do   # equivarent to setUpAll()
      puts "* before_all() called"
    end

    after_all do    # equvarent to tearDownAll()
      puts "* after_all() called"
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
$ oktest test/example21_test.rb    # or: ruby test/example21_test.rb
* before_all() called
** before() called
---- example spec #1 ----
** after() called
.** before() called
---- example spec #2 ----
** after() called
.* after_all() called

## total:2 (pass:2, fail:0, error:0, skip:0, todo:0) in 0.000s
```


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

* `at_end()` can be called multiple times.
* Registered blocks are invoked in reverse order at end of test case.
* Registered blocks of `at_end()` are invoked before blocks of `after()`.


### Fixture Injection

test/example23_test.rb:

```ruby
require 'oktest'

Oktest.scope do

  fixture :alice do               # define fixture
    {name: "Alice", age: 22}
  end

  fixture :bob do                 # define fixture
    {name: "Bob", age: 29}
  end

  fixture :team do |alice, bob|   # !!! fixture injection !!!
    {
      name: "Blabla",
      members: [alice, bob]
    }
  end

  topic "Fixture Injection" do

    spec "example spec" do
      |alice, bob, team|          # !!! fixture injection !!!
      ok {alice[:name]} == "Alice"
      ok {alice[:age]} == 22
      ok {bob[:name]} == "Bob"
      ok {bob[:age]} == 29
      #
      ok {team[:name]} == "Blabla"
      ok {team[:members]}.length(2)
      ok {team[:members][0][:name]} == "Alice"
      ok {team[:members][1][:name]} == "Bob"
    end

  end

end
```

* Fixtures can be defined in block of `topic()` as well as block of `Object.scope()`.
* If fixture requires clean-up operation, call `at_end()` in `fixture()` block.

```ruby
  fixture :tmpfile do
    tmpfile = "tmp#{rand().to_s[2..5]}.txt"
    File.write(tmpfile, "foobar\n", encoding: 'utf-8')
    at_end { File.unlink(tmpfile) if File.exist?(tmpfile) }   # !!!!!
    tmpfile
  end
```


### Global Scope

It is a good idea to separate common fixtures into dedicated file.
In this case, use `Oktest.global_scope()` instead of `Oktest.scope()`.

test/common_fixtures.rb:

```ruby
require 'oktest'

## define common fixtures in global scope
Oktest.global_scope do     # !!!!!

  fixture :alice do
    {name: "Alice", age: 22}
  end

  fixture :bob do
    {name: "Bob", age: 29}
  end

  fixture :team do |alice, bob|
    {
      name: "Blabla",
      members: [alice, bob]
    }
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

* First argument of `capture_sio()` represents data from `$stdin`.
  If it is not necessary, you can omit it like `caputre_sio() do ... end`.
* If you need `$stdin.tty? == true` and `$stdout.tty? == true`,
  call `capture_sio(tty: true) do ... end`.


### `dummy_file()`

`dummy_file()` creates dummy file temporarily.

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

* If first argument of `dummy_file()` is nil, then it generates temporary file name automatically.


### `dummy_dir()`

`dummy_dir()` creates dummy directory temporarily.

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

* If first argument of `dummy_dir()` is nil, then it generates temorary directory name automatically.


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

`recorder()` returns Benry::Recorder object.
See [Benry::Recorder README](https://github.com/kwatch/benry-ruby/blob/ruby/benry-recorder/README.md)
for detals.

test/example37_test.rb:

```ruby
require 'oktest'

class Calc
  def total(*nums)
    t = 0; nums.each {|n| t += n }
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
      rec = recorder()
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
      rec = recorder()
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



## Tips


### `ok {}` in MiniTest

If you want to use `ok {actual} == expected` style assertion in MiniTest,
install `minitest-ok` gem instead of `otest` gem.

test/example41_test.rb:

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

test/example42_test.rb:

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

+ topic "GET /api/hello" do

  - spec "returns JSON data." do
      response = http.GET('/api/hello')        # call Rack app
      ok {response.status}       == 200
      ok {response.content_type} == "application/json"
      ok {response.body_json}    == {"status"=>"OK"}
    end

  end

end
```



## License and Copyright

* $License: MIT License $
* $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
