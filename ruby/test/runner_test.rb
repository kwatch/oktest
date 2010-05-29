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


class OktestRunnerTest < Test::Unit::TestCase

  def case_if(desc)
    yield
  end

  def _runner(reporter_class=Oktest::REPORTER)
    @out = StringIO.new
    @reporter = reporter_class.new(@out)
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
    runner = _runner(Oktest::SimpleReporter)
    runner.run(FooTest1)
    runner.run(FooTest2)
    expected = <<END
### OktestRunnerTest::FooTest1
...
### OktestRunnerTest::FooTest2
...
END
    assert_equal expected, @out.string
    ## before_all()/after_all() should be called only once
    counts = FooTest1.counts
    assert_equal 1, counts[:before_all]
    assert_equal 1, counts[:after_all]
    ## before()/after() should be called for each test
    assert_equal 3, counts[:before]
    assert_equal 3, counts[:after]
    ## setup()/teardown() should not be called if before()/after() defined
    assert_equal 0, counts[:setup]
    assert_equal 0, counts[:teardown]
    ## setup()/teardown() should be called if before()/after() not defined
    counts = FooTest2.counts
    assert_equal 3, counts[:setup]
    assert_equal 3, counts[:teardown]
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
    runner = _runner(Oktest::VerboseReporter)
    runner.run(BarTest2)
    ## test methods are called in order as they are defined (except included methods)
    assert_equal %w[test_aaa test_xxx test_foo test_bar test_001_baz], runner.test_method_names_from(BarTest2)
    expected = <<END
### OktestRunnerTest::BarTest2
- test_aaa ... ok
- test_xxx ... ok
- test_foo ... ok
- test_bar ... ok
- test_001_baz ... ok

END
    assert_equal expected, @out.string
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
    case_if "ENV['TEST'] is specified" do
      ENV['TEST'] = 'bar'
      _runner().run(BazTest1)
      assert_equal({:bar=>true}, BazTest1.invoked)
    end
    ## partial match
    case_if "ENV['TEST'] matches to several test methods" do
      BazTest1.invoked.clear
      ENV['TEST'] = 'ba'
      _runner().run(BazTest1)
      assert_equal({:bar=>true, :baz=>true}, BazTest1.invoked)
    end
    ## if $TEST is not set then all tests are invoked
    case_if "ENV['TEST'] is not specified" do
      ENV.delete('TEST')
      BazTest1.invoked.clear
      _runner().run(BazTest1)
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
    assert_equal(expected, actual)
  end

  def test_oktest_run
    ## :out option
    case_if ':out option is specified' do
      out = StringIO.new
      Oktest.run(BazTest2, :out=>out)
      expected = <<'END'
### OktestRunnerTest::BazTest2
.f
Failed: test_bar()
    2 == 3: failed.
    ./test/runner_test.rb:202:in `test_bar'
      def test_bar; ok(1+1) == 3; end
END
      _assert_equal expected, out.string
    end
    ## :verbose option
    case_if ':verbose option is specified' do
      out = StringIO.new
      Oktest.run(BazTest2, :out=>out, :verbose=>true)
      expected = <<'END'
### OktestRunnerTest::BazTest2
- test_foo ... ok
- test_bar ... FAILED
    2 == 3: failed.
    ./test/runner_test.rb:202:in `test_bar'
      def test_bar; ok(1+1) == 3; end

END
      _assert_equal expected, out.string
    end
  end

end
