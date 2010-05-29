###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'stringio'
require 'oktest'


class OktestReporterTest < Test::Unit::TestCase

  class ExampleTest
    include Oktest::TestCase
    def test_success
      ok(1+1) == 2
    end
    def test_fail
      ok(1+1) == 3
    end
    def test_fail_nested
      _foo(1+1, 3)
    end
    private
    def _foo(*args)
      _bar(*args)
    end
    def _bar(actual, expected)
      ok(actual) == expected
    end
  end

  def _test()
    out = StringIO.new
    reporter = @klass.new(out)
    runner = Oktest::Runner.new(reporter)
    runner.run(ExampleTest)
    actual = out.string
    @debug  and $stderr.puts "\033[0;31m*** debug: out.string=#{out.string}\033[0m"
    expected = @expected
    expected = expected.gsub(%r|^    \./test/|, '    test/') if expected != actual
    assert_equal(expected, actual)
  end

  def test_verbose_reporter
    @klass    = Oktest::VerboseReporter
    @debug    = false
    @expected = \
%q"### OktestReporterTest::ExampleTest
- test_success ... ok
- test_fail ... FAILED
    2 == 3: failed.
    ./test/reporter_test.rb:23:in `test_fail'
      ok(1+1) == 3
- test_fail_nested ... FAILED
    2 == 3: failed.
    ./test/reporter_test.rb:33:in `_bar'
      ok(actual) == expected
    ./test/reporter_test.rb:30:in `_foo'
      _bar(*args)
    ./test/reporter_test.rb:26:in `test_fail_nested'
      _foo(1+1, 3)

"
    _test()
  end

  def test_simple_reporter
    @klass    = Oktest::SimpleReporter
    @debug    = false
    @expected = \
%q"### OktestReporterTest::ExampleTest
.ff
Failed: test_fail()
    2 == 3: failed.
    ./test/reporter_test.rb:23:in `test_fail'
      ok(1+1) == 3
Failed: test_fail_nested()
    2 == 3: failed.
    ./test/reporter_test.rb:33:in `_bar'
      ok(actual) == expected
    ./test/reporter_test.rb:30:in `_foo'
      _bar(*args)
    ./test/reporter_test.rb:26:in `test_fail_nested'
      _foo(1+1, 3)
"
    _test()
  end


end
