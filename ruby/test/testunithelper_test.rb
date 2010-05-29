###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest/unit'


class TestUnitHelperTest < Test::Unit::TestCase


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

  ## self.test() is available
  test "3*3 should be 9" do
    ok(3*3) == 9
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
