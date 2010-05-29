###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require 'oktest'
require 'test/unit'


module Oktest


  module TestUnitHelper

    class AssertionObject < Oktest::AssertionObject

      def do_assert(flag, expected, op, negative_op)
        begin
          flag, msg = check(flag, expected, op, negative_op)
          @this.assert_block(msg) { flag }
        rescue Test::Unit::AssertionFailedError => ex
          manipulate_backtrace(ex.backtrace, __LINE__ - 2)
          raise ex
        end
      end

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

    end


  end


end


class ::Test::Unit::TestCase

  include Oktest::TestCase
  include Oktest::TestUnitHelper::TestCase

end
