###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest/unit'
require 'stringio'


class TestUnitHelperTest < Test::Unit::TestCase


  class FugarTest0 < Test::Unit::TestCase
    def testDummy
    end
  end

  def _setup_FugarTest0
    FugarTest0.class_eval do
      def test_ok
        ## ok() is available
        assert_equal 2, 1+1
        ok(1+1) == 2
      end
      def test_not_ok
        ## not_ok() is available
        assert_equal 2, 1+1
        not_ok(1+1) == 3
      end
      def test_file?
        ok(__FILE__).file?
        not_ok('notexist').file?
        assert_raise(Oktest::AssertionFailed) { ok('notexist').file? }
        assert_raise(Oktest::AssertionFailed) { not_ok(__FILE__).file? }
      end
      def test_raise?
        pr = proc { nil.foo }
        ok(pr).raise?(NoMethodError, "undefined method `foo' for nil:NilClass")
      end
      ## self.test() is available
      test "3*3 should be 9" do
        ok(3*3) == 9
      end
      ##
      def test_fail1a
        assert 3 == 1+1
      end
      def test_fail1b
        ok(1+1) == 3
      end
      def test_fail2a
        assert_equal "AAA\nBBB\nCCC\n", "AAA\nCCC\nDDD\n"
      end
      def test_fail2b
        ok("AAA\nCCC\nDDD\n") == "AAA\nBBB\nCCC\n"
      end
    end
  end

  def _teardown_FugarTest0
    names = FugarTest0.instance_methods().grep(/^test_/)
    FugarTest0.class_eval do
      remove_method *names
    end
  end

  def test_basic
    _setup_FugarTest0()
    io = StringIO.new
    require 'test/unit/ui/console/testrunner'
    runner = Test::Unit::UI::Console::TestRunner.new(FugarTest0, Test::Unit::UI::NORMAL, io)
    runner.start()
    #$stderr.puts "\033[0;31m*** debug: io.string=#{io.string}\033[0m"
    expected = <<'END'
Loaded suite TestUnitHelperTest::FugarTest0
Started
..FFFF....
Finished in 0.014489 seconds.

  1) Failure:
test_fail1a(TestUnitHelperTest::FugarTest0)
    [./test/testunithelper_test.rb:51:in `test_fail1a'
     ./test/testunithelper_test.rb:77:in `test_basic']:
<false> is not true.

  2) Failure:
test_fail1b(TestUnitHelperTest::FugarTest0)
    [./test/testunithelper_test.rb:54:in `test_fail1b'
     ./test/testunithelper_test.rb:77:in `test_basic']:
2 == 3: failed.

  3) Failure:
test_fail2a(TestUnitHelperTest::FugarTest0)
    [./test/testunithelper_test.rb:57:in `test_fail2a'
     ./test/testunithelper_test.rb:77:in `test_basic']:
<"AAA\nBBB\nCCC\n"> expected but was
<"AAA\nCCC\nDDD\n">.

  4) Failure:
test_fail2b(TestUnitHelperTest::FugarTest0)
    [./test/testunithelper_test.rb:60:in `test_fail2b'
     ./test/testunithelper_test.rb:77:in `test_basic']:
"AAA\nCCC\nDDD\n" == "AAA\nBBB\nCCC\n": failed.

10 tests, 11 assertions, 4 failures, 0 errors
END
    actual = io.string
    rexp = /^Finished in \d+.\d+ seconds\.$/
    actual.sub!(rexp, '')
    expected.sub!(rexp, '')
    expected.gsub!(%r|\./test/|, 'test/') if actual != expected
    assert_equal expected, actual
  ensure
    _teardown_FugarTest0()
  end


  ## duplicated method definition is reported
  test "duplicated method definition is reported" do
    ex = assert_raise(NameError) do
      eval <<-END, binding(), __FILE__, __LINE__+1
        class FugarTest1 < Test::Unit::TestCase
          def test1; end
          def test1; end   # duplicated
        end
      END
    end
    expected = 'TestUnitHelperTest::FugarTest1#test1(): already defined (please change test method name).'
    assert_equal expected, ex.message
  end

  ## if $TEST is set, unmatched methods are removed
  test "if $TEST is set, unmatched methods are removed" do
    begin
      ENV['TEST'] = 'ba'
      class FugarTest2 < Test::Unit::TestCase
        def test_foo; end
        def test_bar; end
        def test_baz; end
      end
      arr = FugarTest2.instance_methods.grep(/^test_/).collect {|x| x.to_s }.sort
      assert_equal ['test_bar', 'test_baz'], arr
    ensure
      ENV.delete('TEST')
    end
  end

end
