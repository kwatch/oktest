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
    case_for "ok() ==" do
      assert_nothing_raised { ok(1+1) == 2 }
      ex = assert_raise(_E) { ok(1+1) == 3 }
      assert_equal "2 == 3: failed.", ex.message
    end
    case_for "not_ok() ==" do
      assert_nothing_raised { not_ok(1+1) == 3 }
      ex = assert_raise(_E) { not_ok(1+1) == 2 }
      assert_equal "2 != 2: failed.", ex.message
    end
  end

  def test_lt
    case_for "ok() <" do
      assert_nothing_raised { ok(1+1) < 3 }
      ex = assert_raise(_E) { ok(1+1) < 2 }
      assert_equal "2 < 2: failed.", ex.message
    end
    case_for "not_ok() <" do
      assert_nothing_raised { not_ok(1+1) < 2 }
      ex = assert_raise(_E) { not_ok(1+1) < 3 }
      assert_equal "2 >= 3: failed.", ex.message
    end
  end

  def test_le
    case_for "ok() <=" do
      assert_nothing_raised { ok(1+1) <= 2 }
      ex = assert_raise(_E) { ok(1+1) <= 1 }
      assert_equal "2 <= 1: failed.", ex.message
    end
    case_for "not_ok() <=" do
      assert_nothing_raised { not_ok(1+1) <= 1 }
      ex = assert_raise(_E) { not_ok(1+1) <= 2 }
      assert_equal "2 > 2: failed.", ex.message
    end
  end

  def test_gt
    case_for "ok() >" do
      assert_nothing_raised { ok(1+1) > 1 }
      ex = assert_raise(_E) { ok(1+1) > 2 }
      assert_equal "2 > 2: failed.", ex.message
    end
    case_for "not_ok() >" do
      assert_nothing_raised { not_ok(1+1) > 2 }
      ex = assert_raise(_E) { not_ok(1+1) > 1 }
      assert_equal "2 <= 1: failed.", ex.message
    end
  end

  def test_ge
    case_for "ok() >=" do
      assert_nothing_raised { ok(1+1) >= 2 }
      ex = assert_raise(_E) { ok(1+1) >= 3 }
      assert_equal "2 >= 3: failed.", ex.message
    end
    case_for "not_ok() >=" do
      assert_nothing_raised { not_ok(1+1) >= 3 }
      ex = assert_raise(_E) { not_ok(1+1) >= 2 }
      assert_equal "2 < 2: failed.", ex.message
    end
  end

  def test_equal3
    case_for "ok() ===" do
      assert_nothing_raised { ok(Integer) === 123 }
      ex = assert_raise(_E) { ok(Integer) === "s" }
      assert_equal "Integer === \"s\": failed.", ex.message
    end
    case_for "not_ok() ===" do
      assert_nothing_raised { not_ok(Integer) === "s" }
      ex = assert_raise(_E) { not_ok(Integer) === 123 }
      assert_equal "Integer !== 123: failed.", ex.message
    end
  end

  def test_match
    case_for "ok() =~" do
      assert_nothing_raised { ok(/\w+/) =~ 'foo' }
      ex = assert_raise(_E) { ok(/\s+/) =~ 'foo' }
      assert_equal '/\s+/ =~ "foo": failed.', ex.message
    end
    case_for "not_ok() =~" do
      assert_nothing_raised { not_ok(/\s+/) =~ 'foo' }
      ex = assert_raise(_E) { not_ok(/\w+/) =~ 'foo' }
      assert_equal '/\w+/ !~ "foo": failed.', ex.message
    end
  end

  def test_nearly_equal
    case_for "ok().nearly_equal" do
      assert_nothing_raised { ok(3.14159).nearly_equal(3.1415, 0.0001) }
      ex = assert_raise(_E) { ok(3.14159).nearly_equal(3.1415, 0.00001) }
      assert_equal '(3.14149 <= 3.14159 <= 3.14151): failed.', ex.message
    end
    case_for "not_ok().nearly_equal" do
      assert_nothing_raised { not_ok(3.14159).nearly_equal(3.1415, 0.00001) }
      ex = assert_raise(_E) { not_ok(3.14159).nearly_equal(3.1415, 0.0001) }
      assert_equal '! (3.1414 <= 3.14159 <= 3.1416): failed.', ex.message
    end
  end

  def test_file?
    case_for "ok().file?" do
      assert_nothing_raised { ok(__FILE__).file? }
      ex = assert_raise(_E) { ok('notexist').file? }
      assert_equal "File.file?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok().file?" do
      assert_nothing_raised { not_ok('notexist').file? }
      ex = assert_raise(_E) { not_ok(__FILE__).file? }
      assert_equal "! File.file?(#{__FILE__.inspect}): failed.", ex.message
    end
  end

  def test_dir?
    case_for "ok().dir?" do
      assert_nothing_raised { ok('.').dir? }
      ex = assert_raise(_E) { ok('notexist').dir? }
      assert_equal "File.directory?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok().dir?" do
      assert_nothing_raised { not_ok('notexist').dir? }
      ex = assert_raise(_E) { not_ok('.').dir? }
      assert_equal "! File.directory?(\".\"): failed.", ex.message
    end
  end

  def test_exist?
    case_for "ok().exist?" do
      assert_nothing_raised { ok(__FILE__).exist? }
      assert_nothing_raised { ok('.').exist? }
      ex = assert_raise(_E) { ok('notexist').exist? }
      assert_equal "File.exist?(\"notexist\"): failed.", ex.message
    end
    case_for "not_ok().exist?" do
      assert_nothing_raised { not_ok('notexist').exist? }
      ex = assert_raise(_E) { not_ok(__FILE__).exist? }
      assert_equal "! File.exist?(#{__FILE__.inspect}): failed.", ex.message
      ex = assert_raise(_E) { not_ok('.').exist? }
      assert_equal "! File.exist?(\".\"): failed.", ex.message
    end
  end

  def test_same?
    obj = {}
    case_for "ok().same?" do
      assert_nothing_raised { ok(obj).same? obj }
      ex = assert_raise(_E) { ok(obj).same? obj.dup }
      assert_equal "{}.equal?({}): failed.", ex.message
    end
    case_for "not_ok().same?" do
      assert_nothing_raised { not_ok(obj).same? obj.dup }
      ex = assert_raise(_E) { not_ok(obj).same? obj }
      assert_equal "! {}.equal?({}): failed.", ex.message
    end
  end

  def test_in?
    arr = [10, 20, 30]
    case_for "ok().in?" do
      assert_nothing_raised { ok(20).in? arr }
      ex = assert_raise(_E) { ok(40).in? arr }
      assert_equal "[10, 20, 30].include?(40): failed.", ex.message
    end
    case_for "not_ok().in?" do
      assert_nothing_raised { not_ok(40).in? arr }
      ex = assert_raise(_E) { not_ok(20).in? arr }
      assert_equal "! [10, 20, 30].include?(20): failed.", ex.message
    end
  end

  def test_include?
    arr = [10, 20, 30]
    case_for "ok().include?" do
      assert_nothing_raised { ok(arr).include? 20 }
      ex = assert_raise(_E) { ok(arr).include? 40 }
      assert_equal "[10, 20, 30].include?(40): failed.", ex.message
    end
    case_for "not_ok().include?" do
      assert_nothing_raised { not_ok(arr).include? 40 }
      ex = assert_raise(_E) { not_ok(arr).include? 20 }
      assert_equal "! [10, 20, 30].include?(20): failed.", ex.message
    end
  end

  def test_empty?
    case_for "ok().empty?" do
      assert_nothing_raised { ok([]).empty? }
      ex = assert_raise(_E) { ok([nil]).empty? }
      assert_equal "[nil].empty?: failed.", ex.message
    end
    case_for "not_ok().empty?" do
      assert_nothing_raised { not_ok([nil]).empty? }
      ex = assert_raise(_E) { not_ok([]).empty? }
      assert_equal "! [].empty?: failed.", ex.message
    end
  end

  def test_raise?
    case_for "ok(proc).raise?" do
      errmsg = "undefined method `foo' for nil:NilClass"
      case_when "expected exception is raised" do
        pr = proc { nil.foo }
        assert_nothing_raised do
          ok(pr).raise?(NoMethodError, errmsg)
        end
        assert_kind_of NoMethodError, pr.exception
        assert_equal "undefined method `foo' for nil:NilClass", pr.exception.message
      end
      case_when "subclass of expected exception class is raised" do
        pr = proc { nil.foo }
        assert_nothing_raised do
          ok(pr).raise?(StandardError, errmsg)
        end
        assert_kind_of NoMethodError, pr.exception
        assert_equal "undefined method `foo' for nil:NilClass", pr.exception.message
      end
      case_when "expected exception is not raised" do # fails
        pr = proc { nil.to_s }
        ex = assert_raise(_E) do
          ok(pr).raise?(NoMethodError)
        end
        assert_equal "NoMethodError expected but not raised.", ex.message
      end
      case_when "unexpected exception is raised" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) do
          ok(pr).raise?(ArgumentError, errmsg)
        end
        assert_equal "ArgumentError expected but NoMethodError raised.", ex.message
      end
      case_when "unexpected error message" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) do
          ok(pr).raise?(NoMethodError, "unknown method 'foo'")
        end
        assert_equal "\"undefined method `foo' for nil:NilClass\" == \"unknown method 'foo'\": failed.", ex.message
      end
    end
    case_for "not_ok(proc).raise?" do
      case_when "nothing raised" do
        pr = proc { nil.to_s }
        assert_nothing_raised { not_ok(pr).raise?(Exception) }
      end
      case_when "unexpected exception raised" do # fails
        pr = proc { nil.foo }
        ex = assert_raise(_E) { not_ok(pr).raise?(Exception) }
        assert_equal "unexpected NoMethodError raised.", ex.message
      end
    end
  end


end
