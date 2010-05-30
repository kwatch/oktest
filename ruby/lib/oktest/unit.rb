###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'oktest'
require 'test/unit'


module Oktest

  MINITEST_DEFINED = !! defined?(MiniTest)

  remove_const(:AssertionFailed)
  if MINITEST_DEFINED
    class AssertionFailed < MiniTest::Assertion   # :nodoc:
      attr_accessor :diff
    end
  else
    class AssertionFailed < Test::Unit::AssertionFailedError     # :nodoc:
      attr_accessor :diff
    end
  end


  module TestUnitHelper

    class AssertionObject < Oktest::AssertionObject

      def do_assert(flag, expected, op, negative_op)   # for Test::Unit
        begin
          flag, msg = check(flag, expected, op, negative_op)
          linenum = __LINE__; @this.assert_block(msg) { flag }
        rescue Test::Unit::AssertionFailedError => ex
          manipulate_backtrace(ex.backtrace, linenum)
          raise ex
        end
      end unless MINITEST_DEFINED

      def do_assert(flag, expected, op, negative_op)   # for MiniTest
        begin
          flag, msg = check(flag, expected, op, negative_op)
          linenum = __LINE__; @this.assert(flag, msg)
        rescue MiniTest::Assertion => ex
          manipulate_backtrace(ex.backtrace, linenum)
          raise ex
        end
      end if MINITEST_DEFINED

      def manipulate_backtrace(backtrace, linenum)
        str = "#{__FILE__}:#{linenum}:in `do_assert'"
        idx = backtrace.index {|s| s.index(str) }
        backtrace.delete_at(idx)    # delete "<file>:<line>:in `do_assert'"
        backtrace.delete_at(idx)    # delete "<file>:<line>:in `<op>'"
      end

    end


    module TestCase

      def ok(actual=nil)
        actual = yield if block_given?       # experimental
        return Oktest::TestUnitHelper::AssertionObject.new(self, actual, false)
      end

      def not_ok(actual=nil)
        actual = yield if block_given?       # experimental
        return Oktest::TestUnitHelper::AssertionObject.new(self, actual, true)
      end

      def pre_cond
        yield
      end

      def post_cond
        yield
      end

    end


    module TestCaseClassMethod

      def method_added(name)
        dict = (@_test_method_names_dict ||= {})
        name = name.to_s
        if name =~ /\Atest_?/
          ## if test method name is duplicated, raise error
          dict[name].nil?  or
            raise NameError.new("#{self.name}##{name}(): already defined (please change test method name).")
          dict[name] = dict.size()
          ## if ENV['TEST'] is set, remove unmatched method
          if ENV['TEST']
            remove_method(name) unless name.sub(/\Atest_?/, '').index(ENV['TEST'])
          end
        end
      end

      def test(desc, &block)
        @_test_count ||= 0
        @_test_count += 1
        method_name = "test_%03d_%s" % [@_test_count, desc.to_s.gsub(/[^\w]/, '_')]
        define_method(method_name, block)
      end

    end


  end


end


class ::Test::Unit::TestCase

  #include Oktest::TestCase
  include Oktest::TestUnitHelper::TestCase

  def self.inherited(klass)
    super
    extend Oktest::TestUnitHelper::TestCaseClassMethod
  end

end
