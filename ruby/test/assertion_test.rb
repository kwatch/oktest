###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest';  Oktest.run_at_exit = false


class OktestAssertionTest < Test::Unit::TestCase
  include Oktest::TestCase

  def case_for(desc)
    yield
  end

  alias case_when case_for

  def _E
    Oktest::AssertionFailed
  end

  def test_eq
    case_for "ok_() ==" do
      assert_nothing_raised { ok_(1+1) == 2 }
      ex = assert_raise(_E) { ok_(1+1) == 3 }
      assert_equal "2 == 3: failed.", ex.message
    end
    case_for "not_ok_() ==" do
      assert_nothing_raised { not_ok_(1+1) == 3 }
      ex = assert_raise(_E) { not_ok_(1+1) == 2 }
      assert_equal "2 != 2: failed.", ex.message
    end
  end

  def test_lt
    case_for "ok_() <" do
      assert_nothing_raised { ok_(1+1) < 3 }
      ex = assert_raise(_E) { ok_(1+1) < 2 }
      assert_equal "2 < 2: failed.", ex.message
    end
    case_for "not_ok_() <" do
      assert_nothing_raised { not_ok_(1+1) < 2 }
      ex = assert_raise(_E) { not_ok_(1+1) < 3 }
      assert_equal "2 >= 3: failed.", ex.message
    end
  end

  def test_le
    case_for "ok_() <=" do
      assert_nothing_raised { ok_(1+1) <= 2 }
      ex = assert_raise(_E) { ok_(1+1) <= 1 }
      assert_equal "2 <= 1: failed.", ex.message
    end
    case_for "not_ok_() <=" do
      assert_nothing_raised { not_ok_(1+1) <= 1 }
      ex = assert_raise(_E) { not_ok_(1+1) <= 2 }
      assert_equal "2 > 2: failed.", ex.message
    end
  end

  def test_gt
    case_for "ok_() >" do
      assert_nothing_raised { ok_(1+1) > 1 }
      ex = assert_raise(_E) { ok_(1+1) > 2 }
      assert_equal "2 > 2: failed.", ex.message
    end
    case_for "not_ok_() >" do
      assert_nothing_raised { not_ok_(1+1) > 2 }
      ex = assert_raise(_E) { not_ok_(1+1) > 1 }
      assert_equal "2 <= 1: failed.", ex.message
    end
  end

  def test_ge
    case_for "ok_() >=" do
      assert_nothing_raised { ok_(1+1) >= 2 }
      ex = assert_raise(_E) { ok_(1+1) >= 3 }
      assert_equal "2 >= 3: failed.", ex.message
    end
    case_for "not_ok_() >=" do
      assert_nothing_raised { not_ok_(1+1) >= 3 }
      ex = assert_raise(_E) { not_ok_(1+1) >= 2 }
      assert_equal "2 < 2: failed.", ex.message
    end
  end

  def test_equal3
    case_for "ok_() ===" do
      assert_nothing_raised { ok_(Integer) === 123 }
      ex = assert_raise(_E) { ok_(Integer) === "s" }
      assert_equal "Integer === \"s\": failed.", ex.message
    end
    case_for "not_ok_() ===" do
      assert_nothing_raised { not_ok_(Integer) === "s" }
      ex = assert_raise(_E) { not_ok_(Integer) === 123 }
      assert_equal "Integer !== 123: failed.", ex.message
    end
  end

  def test_match
    case_for "ok_() =~" do
      assert_nothing_raised { ok_(/\w+/) =~ 'foo' }
      ex = assert_raise(_E) { ok_(/\s+/) =~ 'foo' }
      assert_equal '/\s+/ =~ "foo": failed.', ex.message
    end
    case_for "not_ok_() =~" do
      assert_nothing_raised { not_ok_(/\s+/) =~ 'foo' }
      ex = assert_raise(_E) { not_ok_(/\w+/) =~ 'foo' }
      assert_equal '/\w+/ !~ "foo": failed.', ex.message
    end
  end

  def test_in_delta?
    case_for "ok_().in_delta?" do
      assert_nothing_raised { ok_(3.14159).in_delta?(3.1415, 0.0001) }
      ex = assert_raise(_E) { ok_(3.14159).in_delta?(3.1415, 0.00001) }
      assert_equal '(3.14149 <= 3.14159 <= 3.14151): failed.', ex.message
    end
    case_for "not_ok_().in_delta?" do
      assert_nothing_raised { not_ok_(3.14159).in_delta?(3.1415, 0.00001) }
      ex = assert_raise(_E) { not_ok_(3.14159).in_delta?(3.1415, 0.0001) }
      assert_equal '! (3.1414 <= 3.14159 <= 3.1416): failed.', ex.message
    end
  end

  def test_file?
    case_for "ok_().file?" do
      assert_nothing_raised { ok_(__FILE__).file? }
      ex = assert_raise(_E) { ok_('notexist').file? }
      assert_equal "File.file?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok_().file?" do
      assert_nothing_raised { not_ok_('notexist').file? }
      ex = assert_raise(_E) { not_ok_(__FILE__).file? }
      assert_equal "! File.file?(#{__FILE__.inspect}): failed.", ex.message
    end
  end

  def test_dir?
    case_for "ok_().dir?" do
      assert_nothing_raised { ok_('.').dir? }
      ex = assert_raise(_E) { ok_('notexist').dir? }
      assert_equal "File.directory?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok_().dir?" do
      assert_nothing_raised { not_ok_('notexist').dir? }
      ex = assert_raise(_E) { not_ok_('.').dir? }
      assert_equal "! File.directory?(\".\"): failed.", ex.message
    end
  end

  def test_exist?
    case_for "ok_().exist?" do
      assert_nothing_raised { ok_(__FILE__).exist? }
      assert_nothing_raised { ok_('.').exist? }
      ex = assert_raise(_E) { ok_('notexist').exist? }
      assert_equal "File.exist?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok_().exist?" do
      assert_nothing_raised { not_ok_('notexist').exist? }
      ex = assert_raise(_E) { not_ok_(__FILE__).exist? }
      assert_equal "! File.exist?(#{__FILE__.inspect}): failed.", ex.message
      ex = assert_raise(_E) { not_ok_('.').exist? }
      assert_equal "! File.exist?(\".\"): failed.", ex.message
    end
  end

  def test_same?
    obj = {}
    case_for "ok_().same?" do
      assert_nothing_raised { ok_(obj).same? obj }
      ex = assert_raise(_E) { ok_(obj).same? obj.dup }
      assert_equal "{}.equal?({}): failed.", ex.message
    end
    case_for "not_ok_().same?" do
      assert_nothing_raised { not_ok_(obj).same? obj.dup }
      ex = assert_raise(_E) { not_ok_(obj).same? obj }
      assert_equal "! {}.equal?({}): failed.", ex.message
    end
  end

  def test_in?
    arr = [10, 20, 30]
    case_for "ok_().in?" do
      assert_nothing_raised { ok_(20).in? arr }
      ex = assert_raise(_E) { ok_(40).in? arr }
      assert_equal "[10, 20, 30].include?(40): failed.", ex.message
    end
    case_for "not_ok_().in?" do
      assert_nothing_raised { not_ok_(40).in? arr }
      ex = assert_raise(_E) { not_ok_(20).in? arr }
      assert_equal "! [10, 20, 30].include?(20): failed.", ex.message
    end
  end

  def test_include?
    arr = [10, 20, 30]
    case_for "ok_().include?" do
      assert_nothing_raised { ok_(arr).include? 20 }
      ex = assert_raise(_E) { ok_(arr).include? 40 }
      assert_equal "[10, 20, 30].include?(40): failed.", ex.message
    end
    case_for "not_ok_().include?" do
      assert_nothing_raised { not_ok_(arr).include? 40 }
      ex = assert_raise(_E) { not_ok_(arr).include? 20 }
      assert_equal "! [10, 20, 30].include?(20): failed.", ex.message
    end
  end

  def test_is_a?
    val= 1
    case_for "ok_().is_a?" do
      assert_nothing_raised { ok_(val).is_a?(Fixnum) }
      assert_nothing_raised { ok_(val).is_a?(Integer) }
      ex = assert_raise(_E) { ok_(val).is_a?(Float) }
      assert_equal "1.is_a?(Float): failed.", ex.message
    end
    case_for "not_ok_().is_a?" do
      assert_nothing_raised { not_ok_(val).is_a?(Float) }
      ex = assert_raise(_E) { not_ok_(val).is_a?(Fixnum) }
      assert_equal "! 1.is_a?(Fixnum): failed.", ex.message
      ex = assert_raise(_E) { not_ok_(val).is_a?(Integer) }
      assert_equal "! 1.is_a?(Integer): failed.", ex.message
    end
  end

  def test_nil?
    case_for "ok_().nil?" do
      assert_nothing_raised { ok_(nil).nil? }
      ex = assert_raise(_E) { ok_(false).nil? }
      assert_equal "false.nil?: failed.", ex.message
    end
    case_for "not_ok_().nil?" do
      assert_nothing_raised { not_ok_(false).nil? }
      ex = assert_raise(_E) { not_ok_(nil).nil? }
      assert_equal "! nil.nil?: failed.", ex.message
    end
  end

  def test_empty?
    case_for "ok_().empty?" do
      assert_nothing_raised { ok_([]).empty? }
      ex = assert_raise(_E) { ok_([nil]).empty? }
      assert_equal "[nil].empty?: failed.", ex.message
    end
    case_for "not_ok_().empty?" do
      assert_nothing_raised { not_ok_([nil]).empty? }
      ex = assert_raise(_E) { not_ok_([]).empty? }
      assert_equal "! [].empty?: failed.", ex.message
    end
  end

  def test_raise?
    case_for "ok_(proc).raise?" do
      errmsg = "undefined method `foo' for nil:NilClass"
      case_when "expected exception is raised" do
        pr = proc { nil.foo }
        ex = nil
        assert_nothing_raised do
          ex = ok_(pr).raise?(NoMethodError, errmsg)
        end
        assert_kind_of NoMethodError, pr.exception
        assert_equal "undefined method `foo' for nil:NilClass", pr.exception.message
        assert_same pr.exception, ex
      end
      case_when "subclass of expected exception class is raised" do
        pr = proc { nil.foo }
        assert_nothing_raised do
          ok_(pr).raise?(StandardError, errmsg)
        end
        assert_kind_of NoMethodError, pr.exception
        assert_equal "undefined method `foo' for nil:NilClass", pr.exception.message
      end
      case_when "expected exception is not raised" do # fails
        pr = proc { nil.to_s }
        ex = assert_raise(_E) do
          ok_(pr).raise?(NoMethodError)
        end
        assert_equal "NoMethodError expected but not raised.", ex.message
      end
      case_when "unexpected exception is raised" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) do
          ok_(pr).raise?(ArgumentError, errmsg)
        end
        assert_equal "ArgumentError expected but NoMethodError raised.", ex.message
      end
      case_when "unexpected error message" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) do
          ok_(pr).raise?(NoMethodError, "unknown method 'foo'")
        end
        assert_equal "\"undefined method `foo' for nil:NilClass\" == \"unknown method 'foo'\": failed.", ex.message
      end
      case_when "error message is specified as Regexp" do
        pr = proc { nil.foo }
        assert_nothing_raised(Exception) do
          ok_(pr).raise?(NoMethodError, /^undefined method `\w+'/)
        end
      end
    end
    case_for "not_ok_(proc).raise?" do
      case_when "nothing raised" do
        pr = proc { nil.to_s }
        assert_nothing_raised { not_ok_(pr).raise?(Exception) }
      end
      case_when "unexpected exception raised" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) { not_ok_(pr).raise?(Exception) }
        assert_equal "unexpected NoMethodError raised.", ex.message
      end
    end
  end


end
