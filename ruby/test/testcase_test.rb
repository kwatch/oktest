###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest'


class OktestTestCaseTest < Test::Unit::TestCase

  ##
  ## duplicated method should be reported
  ##

  def test_method_added
    ex = assert_raise(NameError) do
      eval <<-END, binding(), __FILE__, __LINE__+1
      class HogeTest1
        include Oktest::TestCase
        def test1; ok(1+1)==2; end
        def test1; ok(1+1)==2; end    # duplicated method
      end
      END
    end
    expected = "OktestTestCaseTest::HogeTest1#test1(): already defined (please change test method name)."
    assert_equal expected, ex.message
  end


  ##
  ## self.test() defines test method
  ##

  class HogeTest2
    include Oktest::TestCase
    test "1+1 should be 2" do
      ok(1+1) == 2
    end
    test "1-1 should be 0" do
      ok(1-1) == 0
    end
  end

  def test_test
    test_method_names = HogeTest2.instance_methods().collect {|sym| sym.to_s }.grep(/\Atest_/).sort
    expected = ['test_001_1_1_should_be_2', 'test_002_1_1_should_be_0']
    assert_equal expected, test_method_names
  end


  ##
  ## pre_cond(), post_cond(), case_for(), case_if()
  ##

  class HogeTest3
    include Oktest::TestCase
    def call_pre_cond
      done = false
      pre_cond { done = true }
      return done
    end
    def call_post_cond
      done = false
      post_cond { done = true }
      return done
    end
    def call_case_for
      done = false
      case_for("desc") { done = true }
      return done
    end
    def call_case_if
      done = false
      case_if("desc") { done = true }
      return done
    end
  end

  def test_pre_cond
    assert_equal true, HogeTest3.new.call_pre_cond
  end

  def test_post_cond
    assert_equal true, HogeTest3.new.call_post_cond
  end

  def test_case_for
    assert_equal true, HogeTest3.new.call_case_for
  end

  def test_case_if
    assert_equal true, HogeTest3.new.call_case_if
  end


  ##
  ## 'include Oktest::TestCase' sets Oktest::TestCase._subclasses automatically
  ##
  def test__subclasses
    classes = Oktest::TestCase._subclasses()
    assert classes.include?(HogeTest2)
    assert classes.include?(HogeTest3)
  end


end
