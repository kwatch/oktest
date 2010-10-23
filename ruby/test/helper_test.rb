###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest'


class OktestHelperTest < Test::Unit::TestCase
  include Oktest::Helper

  def case_for(desc)
    yield
  end


  def test_ok_
    assert_equal Oktest::AssertionObject, ok_(nil).class
    ex = assert_raise ArgumentError do
      ok_ { nil }
    end
    assert_equal "wrong number of arguments (0 for 1)", ex.message
  end

  def test_ok
    assert_equal Oktest::AssertionObject, ok {nil}.class
    ex = assert_raise ArgumentError do
      ok(nil)
    end
    assert_equal "wrong number of arguments (1 for 0)", ex.message
  end

  def test_not_ok_
    assert_equal Oktest::AssertionObject, not_ok_(nil).class
    ex = assert_raise ArgumentError do
      not_ok_ { nil }
    end
    assert_equal "wrong number of arguments (0 for 1)", ex.message
  end

  def test_not_ok
    assert_equal Oktest::AssertionObject, not_ok {nil}.class
    ex = assert_raise ArgumentError do
      not_ok(nil)
    end
    assert_equal "wrong number of arguments (1 for 0)", ex.message
  end


end
