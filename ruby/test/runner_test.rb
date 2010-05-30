###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'stringio'
require 'oktest/unit';  Oktest.run_at_exit = false


class OktestRunnerTest < Test::Unit::TestCase

  def _capture_io
    stdout, stderr = $stdout, $stderr
    begin
      $stdout, $stderr = StringIO.new, StringIO.new
      yield
      ret = [$stdout.string, $stderr.string]
    ensure
      $stdout, $stderr = stdout, stderr
    end
    return ret
  end

  def _runner(reporter_class=Oktest.REPORTER())
    @reporter = reporter_class.new()
    @runner = Oktest::Runner.new(@reporter)
    return @runner
  end

  # ----------------------------------------

  class FooTest1
    include Oktest::TestCase

    @@counts = Hash.new {0}

    def self.counts
      return @@counts
    end

    def self.before_all ;  @@counts[:before_all] += 1 ;  end
    def self.after_all  ;  @@counts[:after_all]  += 1 ;  end
    def before   ;  @@counts[:before]   += 1 ;  end
    def after    ;  @@counts[:after]    += 1 ;  end
    def setup    ;  @@counts[:setup]    += 1 ;  end
    def teardown ;  @@counts[:teardown] += 1 ;  end

    def test_foo
      ok(@@counts[:before_all]) == 1
      ok(@@counts[:after_all]) == 0
    end

    def test_bar
      ok(@@counts[:before_all]) == 1
      ok(@@counts[:after_all]) == 0
    end

    def test_baz
      ok(@@counts[:before_all]) == 1
      ok(@@counts[:after_all]) == 0
    end

  end

  class FooTest2
    include Oktest::TestCase

    @@counts = Hash.new {0}

    def self.counts
      return @@counts
    end

    def setup    ;  @@counts[:setup]    += 1 ;  end
    def teardown ;  @@counts[:teardown] += 1 ;  end
    def before_all ; @@counts[:_before_all_] += 1 ;  end
    def after_all  ; @@counts[:_after_all_]  += 1 ;  end

    def test_foo
      ok(1+1) == 2
    end

    def test_bar
      ok(1+1) == 2
    end

    def test_baz
      ok(1+1) == 2
    end

  end

  def test_run
    #Oktest.run(FooTest)
    sout, serr = _capture_io do
      runner = _runner(Oktest::SimpleReporter)
      runner.run(FooTest1)
      runner.run(FooTest2)
    end
    expected = <<END
### OktestRunnerTest::FooTest1
...
### OktestRunnerTest::FooTest2
...
END
    assert_equal expected, sout
    #
    counts = FooTest1.counts
    spec "before_all()/after_all() should be called only once" do
      assert_equal 1, counts[:before_all]
      assert_equal 1, counts[:after_all]
    end
    spec "before()/after() should be called for each test" do
      assert_equal 3, counts[:before]
      assert_equal 3, counts[:after]
    end
    spec "setup()/teardown() should not be called if before()/after() defined" do
      assert_equal 0, counts[:setup]
      assert_equal 0, counts[:teardown]
    end
    #
    counts = FooTest2.counts
    spec "setup()/teardown() should be called if before()/after() not defined" do
      assert_equal 3, counts[:setup]
      assert_equal 3, counts[:teardown]
    end
    spec "before_all()/after_all() should not be called if they are not class methods" do
      assert_equal 0, counts[:_before_all_]
      assert_equal 0, counts[:_after_all_]
    end
    spec "if before_all()/after_all() is defined as instance method then warned it" do
      expected = <<'END'
WARNING: OktestRunnerTest::FooTest2#before_all() should be class method (but defined as instance method)
WARNING: OktestRunnerTest::FooTest2#after_all() should be class method (but defined as instance method)
END
      assert_equal expected, serr
    end
  end

  # ----------------------------------------

  module BarTest1
    def test_xxx
      ok(1+1) == 2
    end
    def test_aaa
      ok(1+1) == 2
    end
  end

  class BarTest2
    include Oktest::TestCase
    def test_foo
      ok(1+1) == 2
    end
    def test_bar
      ok(1+1) == 2
    end
    test "baz" do
      ok(1+1) == 2
    end
    include BarTest1
  end

  def test_test_method_names
    ##
    #Oktest.run(FooTest)
    runner = nil
    sout, serr = _capture_io() do
      runner = _runner(Oktest::VerboseReporter)
      runner.run(BarTest2)
    end
    spec "test methods are called in order as they are defined (except included methods)" do
      assert_equal %w[test_aaa test_xxx test_foo test_bar test_001_baz], runner.test_method_names_from(BarTest2)
      expected = <<END
### OktestRunnerTest::BarTest2
- test_aaa ... ok
- test_xxx ... ok
- test_foo ... ok
- test_bar ... ok
- test_001_baz ... ok

END
      assert_equal expected, sout
    end
  end

  # ----------------------------------------

  class BazTest1
    include Oktest::TestCase
    @@invoked = {}
    def self.invoked; @@invoked; end
    def test_foo; @@invoked[:foo] = true; end
    def test_bar; @@invoked[:bar] = true; end
    def test_baz; @@invoked[:baz] = true; end
  end

  def test_ENV_TEST
    ## $TEST limits test names
    spec "if ENV['TEST'] is specified then test method names are filtered by it" do
      ENV['TEST'] = 'bar'
      _capture_io() { _runner().run(BazTest1) }
      assert_equal({:bar=>true}, BazTest1.invoked)
    end
    ## partial match
    spec "ENV['TEST'] allows partial matching to test method names" do
      BazTest1.invoked.clear
      ENV['TEST'] = 'ba'
      _capture_io() { _runner().run(BazTest1) }
      assert_equal({:bar=>true, :baz=>true}, BazTest1.invoked)
    end
    ## if $TEST is not set then all tests are invoked
    spec "if ENV['TEST'] is not specified then nothing is filtered" do
      ENV.delete('TEST')
      BazTest1.invoked.clear
      _capture_io() { _runner().run(BazTest1) }
      assert_equal({:foo=>true, :bar=>true, :baz=>true}, BazTest1.invoked)
    end
  ensure
    ENV.delete('TEST')
  end

  # ----------------------------------------

  class BazTest2
    include Oktest::TestCase
    def test_foo; ok(1+1) == 2; end
    def test_bar; ok(1+1) == 3; end
  end

  def _assert_equal(expected, actual)
    expected = expected.gsub(%r|^    \./test/|, '    test/') if expected != actual
    expected = expected.gsub(%r|test/runner_test\.rb|, __FILE__) if expected != actual && RUBY_VERSION >= '1.9'
    assert_equal(expected, actual)
  end

  def test_oktest_run
    ## :out option
    spec 'if :out option is specified then output is stealed by it' do
      out = StringIO.new
      Oktest.run(BazTest2, :out=>out)
      expected = <<'END'
### OktestRunnerTest::BazTest2
.f
Failed: test_bar()
    2 == 3: failed.
    ./test/runner_test.rb:234:in `test_bar'
      def test_bar; ok(1+1) == 3; end
END
      _assert_equal expected, out.string
    end
    ## :verbose option
    spec 'if :verbose option is specified then test method names are displayed' do
      out = StringIO.new
      Oktest.run(BazTest2, :out=>out, :verbose=>true)
      expected = <<'END'
### OktestRunnerTest::BazTest2
- test_foo ... ok
- test_bar ... FAILED
    2 == 3: failed.
    ./test/runner_test.rb:234:in `test_bar'
      def test_bar; ok(1+1) == 3; end

END
      _assert_equal expected, out.string
    end
    ## set '@_run_at_exit = true'
    spec 'if called then disabled run-at-exist' do
      Oktest.run_at_exit = true
      assert_equal true, Oktest.run_at_exit?
      out = StringIO.new
      Oktest.run(BazTest2, :out=>out)
      assert_equal false, Oktest.run_at_exit?
    end
  end

  # ----------------------------------------

  def test_at_exit
    content1 = <<'END'
$: << './lib' << '../lib'
require 'oktest'
Oktest.REPORTER = Oktest::VerboseReporter

class FooTest
  include Oktest::TestCase
  test 'dummy1' do
    ok(1+1) == 2
  end
end
END
    content2 = <<'END'
$: << './lib' << '../lib'
require 'test/unit'
require 'oktest/unit'
Oktest.REPORTER = Oktest::VerboseReporter

class FooTest
  include Oktest::TestCase
  test 'dummy1' do
    ok(1+1) == 2
  end
end

class BarTest < Test::Unit::TestCase
  test 'dummy2' do
    ok(1+1) == 2
  end
end
END
    expected = <<'END'
### FooTest
- test_001_dummy1 ... ok

END
    fname = '_test_at_exit.rb'
    spec "if neither run() nor run_all() is called then run at exit" do
      File.open(fname, 'w') {|f| f.write(content1) }
      assert_equal expected, `ruby #{fname}`
    end
    spec "if either run() or runall() is called then do nothing" do
      File.open(fname, 'w') {|f| f.write(content1 + "Oktest.run()\n") }
      assert_equal "", `ruby #{fname}`
    end
    spec "if Oktest.run_at_exit=false then do nothing" do
      File.open(fname, 'w') {|f| f.write(content1 + "Oktest.run_at_exit = false\n") }
      assert_equal "", `ruby #{fname}`
    end
    spec "subclasses of Test::Unit::TestCase are not run" do
      File.open(fname, 'w') {|f| f.write(content2) }
      assert_equal expected, `ruby #{fname}`
    end
  ensure
    File.unlink(fname) if File.exist?(fname)
  end

end
