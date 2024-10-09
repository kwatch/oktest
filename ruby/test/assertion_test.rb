# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest::AssertionObject
  extend NanoTest
  extend Oktest::SpecHelper

  def self.FAIL!(errmsg, &b)
    failmsg = "expected to be failed, but succeeded unexpectedly."
    return ERROR!(Oktest::FAIL_EXCEPTION, errmsg, failmsg, &b)
  end

  def self.ERROR!(errcls, errmsg=nil, _failmsg=nil, &b)
    exc = nil
    begin
      yield
    rescue Exception => exc_
      exc = exc_
      errcls == exc_.class or
        raise
    else
      _failmsg ||= "#{errcls} expected to be raised, but nothing raised."
      test_ok? false, _failmsg
    end
    #
    if errmsg
      test_ok? errmsg === exc.message,
              msg: ("unexpected error message:\n"\
                    "  expected: #{errmsg}\n"\
                    "  actual:   #{exc.message}")
    end
    #
    return exc
  end

  def self.PASS!(&b)
    yield
  end

  def self.should_return_self(&b)
    obj = yield
    test_ok? obj.class == Oktest::AssertionObject
  end


  test_target 'Oktest::AssertionObject.report_not_yet()' do
    test_subject "[!3nksf] reports if 'ok{}' called but assertion not performed." do
      test_ok? Oktest::AssertionObject::NOT_YET.empty?, msg: "should be empty"
      sout, serr = capture_output! do
        Oktest::AssertionObject.report_not_yet()
      end
      test_eq? sout, ""
      test_eq? serr, ""
      #
      lineno = __LINE__ + 1
      ok {1+1}
      test_ok? ! Oktest::AssertionObject::NOT_YET.empty?, msg: "should not be empty"
      sout, serr = capture_output! { Oktest::AssertionObject.report_not_yet() }
      expected = "** warning: ok() is called but not tested yet (at #{__FILE__}:#{lineno}:in"
      test_eq? sout, ""
      test_ok? serr.start_with?(expected), msg: "not matched"
    end
    test_subject "[!f92q4] clears remained objects." do
      ok {1+1}
      test_ok? ! Oktest::AssertionObject::NOT_YET.empty?, msg: "should not be empty"
      sout, serr = capture_output! { Oktest::AssertionObject.report_not_yet() }
      test_ok? Oktest::AssertionObject::NOT_YET.empty?, msg: "should be empty"
    end
  end

  test_target 'Oktest::AssertionObject.NOT()' do
    test_subject "[!g775v] returns self." do
      begin
        should_return_self { ok {1+1}.NOT }
      ensure
        Oktest::AssertionObject::NOT_YET.clear()
      end
    end
    test_subject "[!63dde] toggles internal boolean." do
      begin
        x = ok {1+1}
        test_eq? x.bool, true
        x.NOT
        test_eq? x.bool, false
      ensure
        Oktest::AssertionObject::NOT_YET.clear()
      end
    end
  end

  test_target 'Oktest::AssertionObject#==' do
    test_subject "[!c6p0e] returns self when passed." do
      should_return_self { ok {1+1} == 2 }
    end
    test_subject "[!1iun4] raises assertion error when failed." do
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {1+1} == 3 }
    end
    test_subject "[!eyslp] is avaialbe with NOT." do
      PASS! { ok {1+1}.NOT == 3 }
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {1+1}.NOT == 2 }
    end
    test_subject "[!3xnqv] shows context diff when both actual and expected are text." do
      expected = "Haruhi\nMikuru\nYuki\n"
      actual   = "Haruhi\nMichiru\nYuki\n"
      errmsg = <<'END'
$<actual> == $<expected>: failed.
--- $<expected>
+++ $<actual>
@@ -1,4 +1,4 @@
 Haruhi
-Mikuru
+Michiru
 Yuki
END
      #errmsg.gsub!(/1,4/, '1,3') if RUBY_VERSION < "1.9.2"
      errmsg.gsub!(/1,4/, '1,3') unless defined?(Diff::LCS)
      FAIL!(errmsg) { ok {actual} == expected }
    end
  end

  test_target 'Oktest::AssertionObject#!=' do
    test_subject "[!iakbb] returns self when passed." do
      should_return_self { ok {1+1} != 3 }
    end
    test_subject "[!90tfb] raises assertion error when failed." do
      #errmsg = "<2> expected to be != to\n<2>."
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {1+1} != 2 }
    end
    test_subject "[!l6afg] is avaialbe with NOT." do
      PASS! { ok {1+1}.NOT != 2 }
      #errmsg = "<3> expected but was\n<2>."
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {1+1}.NOT != 3 }
    end
  end #if RUBY_VERSION >= "1.9"

  test_target 'Oktest::AssertionObject#===' do
    test_subject "[!uh8bm] returns self when passed." do
      should_return_self { ok {String} === 'str' }
    end
    test_subject "[!42f6a] raises assertion error when failed." do
      errmsg = "$<actual> === $<expected>: failed.\n"\
               "    $<actual>:   Integer\n"\
               "    $<expected>: \"str\""
      FAIL!(errmsg) { ok {Integer} === 'str' }
    end
    test_subject "[!vhvyu] is avaialbe with NOT." do
      PASS! { ok {Integer}.NOT === 'str' }
      errmsg = "!($<actual> === $<expected>): failed.\n"\
               "    $<actual>:   String\n"\
               "    $<expected>: \"str\""
      FAIL!(errmsg) { ok {String}.NOT === 'str' }
    end
    test_subject "[!mjh4d] raises error when combination of 'not_ok()' and matcher object." do
      errmsg = "negative `===` is not available with matcher object."
      exc = test_exception? Oktest::OktestError do
        not_ok {Oktest::JsonMatcher.new({})} === {}
      end
      test_eq? errmsg, exc.message
      exc = test_exception? Oktest::OktestError do
        ok {Oktest::JsonMatcher.new({})}.NOT === {}
      end
      test_eq? errmsg, exc.message
    end
  end

  test_target 'Oktest::AssertionObject>' do
    test_subject "[!3j7ty] returns self when passed." do
      should_return_self { ok {2} > 1 }
    end
    test_subject "[!vjjuq] raises assertion error when failed." do
      #errmsg = "Expected 2 to be > 2."
      errmsg = "2 > 2: failed."
      FAIL!(errmsg) { ok {2} > 2 }
      errmsg = "1 > 2: failed."
      FAIL!(errmsg) { ok {1} > 2 }
      #
      errmsg = "\"aaa\" > \"bbb\": failed."
      FAIL!(errmsg) { ok {'aaa'} > 'bbb' }
    end
    test_subject "[!73a0t] is avaialbe with NOT." do
      PASS! { ok {2}.NOT > 2 }
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      FAIL!(errmsg) { ok {2}.NOT > 1 }
    end
  end

  test_target 'Oktest::AssertionObject>=' do
    test_subject "[!75iqw] returns self when passed." do
      should_return_self { ok {2} >= 2 }
      should_return_self { ok {2} >= 1 }
    end
    test_subject "[!isdfc] raises assertion error when failed." do
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      FAIL!(errmsg) { ok {1} >= 2 }
      #
      errmsg = "\"aaa\" >= \"bbb\": failed."
      FAIL!(errmsg) { ok {'aaa'} >= 'bbb' }
    end
    test_subject "[!3dgmh] is avaialbe with NOT." do
      PASS! { ok {1}.NOT >= 2 }
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      FAIL!(errmsg) { ok {2}.NOT >= 2 }
    end
  end

  test_target 'Oktest::AssertionObject<' do
    test_subject "[!vkwcc] returns self when passed." do
      should_return_self { ok {1} < 2 }
    end
    test_subject "[!ukqa0] raises assertion error when failed." do
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      FAIL!(errmsg) { ok {2} < 2 }
      errmsg = "2 < 1: failed."
      FAIL!(errmsg) { ok {2} < 1 }
      #
      errmsg = "\"bbb\" < \"aaa\": failed."
      FAIL!(errmsg) { ok {'bbb'} < 'aaa' }
    end
    test_subject "[!gwvdl] is avaialbe with NOT." do
      PASS! { ok {2}.NOT < 2 }
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      FAIL!(errmsg) { ok {1}.NOT < 2 }
    end
  end

  test_target 'Oktest::AssertionObject<=' do
    test_subject "[!yk7t2] returns self when passed." do
      should_return_self { ok {1} <= 2 }
      should_return_self { ok {1} <= 1 }
    end
    test_subject "[!ordwe] raises assertion error when failed." do
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      FAIL!(errmsg) { ok {2} <= 1 }
      #
      errmsg = "\"bbb\" <= \"aaa\": failed."
      FAIL!(errmsg) { ok {'bbb'} <= 'aaa' }
    end
    test_subject "[!mcb9w] is avaialbe with NOT." do
      PASS! { ok {2}.NOT <= 1 }
      #errmsg = "Expected 1 to be > 2."
      errmsg = "1 > 2: failed."
      FAIL!(errmsg) { ok {1}.NOT <= 2 }
    end
  end

  test_target 'Oktest::AssertionObject=~' do
    test_subject "[!acypf] returns self when passed." do
      should_return_self { ok {'SOS'} =~ /^[A-Z]+$/ }
    end
    test_subject "[!xkldu] raises assertion error when failed." do
      #errmsg = 'Expected /^\\d+$/ to match "SOS".'
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /^\\d+$/\n"\
               "    $<actual>:   <<'END'\n"\
               "SOS\n"\
               "END\n"
      FAIL!(errmsg) { ok {"SOS\n"} =~ /^\d+$/ }
    end
    test_subject "[!2aa6f] is avaialbe with NOT." do
      PASS! { ok {'SOS'}.NOT =~ /^\d+$/ }
      #errmsg = "</\\w+/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /\\w+/\n"\
               "    $<actual>:   \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'}.NOT =~ /\w+/ }
    end if false
  end

  test_target 'Oktest::AssertionObject!~' do
    test_subject "[!xywdr] returns self when passed." do
      should_return_self { ok {'SOS'} !~ /^\d+$/ }
    end
    test_subject "[!58udu] raises assertion error when failed." do
      #errmsg = "</^\\w+$/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /^\\w+$/\n"\
               "    $<actual>:   \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'} !~ /^\w+$/ }
    end
    test_subject "[!iuf5j] is avaialbe with NOT." do
      PASS! { ok {'SOS'}.NOT !~ /^\w+$/ }
      #errmsg = "Expected /\\d+/ to match \"SOS\"."
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /\\d+/\n"\
               "    $<actual>:   <<'END'\nSOS\nEND\n"
      FAIL!(errmsg) { ok {"SOS\n"}.NOT !~ /\d+/ }
    end
  end #if RUBY_VERSION >= "1.9"

  test_target 'Oktest::AssertionObject#in_delta?' do
    test_subject "[!m0791] returns self when passed." do
      should_return_self { ok {3.14159}.in_delta?(3.141, 0.001) }
    end
    test_subject "[!f3zui] raises assertion error when failed." do
      errmsg = "($<actual> - $<expected>).abs < #{0.1}: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      FAIL!(errmsg) { ok {1.375}.in_delta?(1.5, 0.1) }
    end
    test_subject "[!t7liw] is avaialbe with NOT." do
      PASS! { ok {1.375}.NOT.in_delta?(1.5, 0.1) }
      errmsg = "($<actual> - $<expected>).abs < #{0.2} == false: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      FAIL!(errmsg) { ok {1.375}.NOT.in_delta?(1.5, 0.2) }
    end
  end

  test_target 'Oktest::AssertionObject#same?' do
    test_subject "[!yk7zo] returns self when passed." do
      should_return_self { ok {:SOS}.same?(:SOS) }
    end
    test_subject "[!ozbf4] raises assertion error when failed." do
      errmsg = "$<actual>.equal?($<expected>): failed.\n"\
               "    $<actual>:   \"SOS\"\n"\
               "    $<expected>: \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'.dup}.same?('SOS') }
    end
    test_subject "[!dwtig] is avaialbe with NOT." do
      PASS! { ok {'SOS'.dup}.NOT.same? 'SOS' }
      errmsg = "$<actual>.equal?($<expected>) == false: failed.\n"\
               "    $<actual>:   :SOS\n"\
               "    $<expected>: :SOS\n"
      FAIL!(errmsg) { ok {:SOS}.NOT.same?(:SOS) }
    end
  end

  test_target 'Oktest::AssertionObject#method_missing()' do
    test_subject "[!7bbrv] returns self when passed." do
      should_return_self { ok {"file.png"}.end_with?(".png") }
    end
    test_subject "[!yjnxb] enables to handle boolean methods." do
      PASS! { ok {""}.empty?  }
      PASS! { ok {nil}.nil?  }
      PASS! { ok {1}.is_a?(Integer)  }
    end
    test_subject "[!ttow6] raises NoMethodError when not a boolean method." do
      ERROR!(NoMethodError) do
        ok {"a"}.start_with
      end
    end
    test_subject "[!gd3vg] supports keyword arguments on Ruby >= 2.7." do
      #if RUBY_VERSION >= "2.7"
      if true
        eval <<-END
          class Dummy392
            def foo?(a, b, c: nil, d: nil)
              return true
            end
          end
        END
        PASS! { ok {Dummy392.new}.foo?(123, 'abc', c: 45, d: true) }
        if RUBY_VERSION >= "2.7"
          errmsg = "unknown keywords: :x, :y"
        else
          errmsg = "unknown keywords: x, y"
        end
        ERROR!(ArgumentError, errmsg) do
          ok {Dummy392.new}.foo?(123, 'abc', x: 45, y: true)
        end
      end
    end
    test_subject "[!f0ekh] skip top of backtrace when NoMethodError raised." do
      exc = ERROR!(NoMethodError) do
        ok {[1]}.start_with?(1)
      end
      test_ok? exc.backtrace[0] !~ /\/oktest\.rbc?:/, msg: "backtrace not skipped"
      test_ok? exc.backtrace[0].start_with?(__FILE__), msg: "backtrace not skipped"
    end
    test_subject "[!cun59] fails when boolean method failed returned false." do
      errmsg = "$<actual>.empty?: failed.\n    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.empty? }
      errmsg = "$<actual>.nil?: failed.\n    $<actual>:   \"\""
      FAIL!(errmsg) { ok {""}.nil? }
      errmsg = "$<actual>.is_a?(Integer): failed.\n    $<actual>:   3.14"
      FAIL!(errmsg) { ok {3.14}.is_a?(Integer) }
    end
    test_subject "[!4objh] is available with NOT." do
      ok {"SOS"}.NOT.empty?
      ok {"SOS"}.NOT.nil?
      ok {"SOS"}.NOT.is_a?(Integer)
      errmsg = "$<actual>.empty? == false: failed.\n    $<actual>:   \"\""
      FAIL!(errmsg) { ok {""}.NOT.empty? }
      errmsg = "$<actual>.nil? == false: failed.\n    $<actual>:   nil"
      FAIL!(errmsg) { ok {nil}.NOT.nil? }
      errmsg = "$<actual>.is_a?(Integer) == false: failed.\n    $<actual>:   1"
      FAIL!(errmsg) { ok {1}.NOT.is_a?(Integer) }
    end
    test_subject "[!sljta] raises TypeError when boolean method returned non-boolean value." do
      errmsg = "ok(): String#sos?() expected to return true or false, but got 1."
      ERROR!(TypeError, errmsg) do
        s = "SOS".dup
        def s.sos?; return 1; end
        ok {s}.sos?
      end
    end
    test_subject "[!5y9iu] reports args and kwargs in error message." do
      if RUBY_VERSION >= "2.7"
        str = '123, "abc", x: "45", y: true'
      else
        str = '123, "abc", {:x=>"45", :y=>true}'
      end
      errmsg = "$<actual>.bla?(#{str}): failed.\n"\
               "    $<actual>:   \"Blabla\""
      FAIL!(errmsg) do
        s = "Blabla".dup
        def s.bla?(*a, **k); return false; end
        ok {s}.bla?(123, "abc", x: "45", y: true)
      end
      #
      obj = Oktest::AssertionObject.new(nil, true, nil)
      expected = '(123, "abc", c: "45", d: true)'
      actual = obj.instance_eval {
        __inspect_args_and_kwargs([123, "abc"], c: "45", d: true)
      }
      test_eq? actual, expected
    end
  end

  test_target 'Oktest::AssertionObject#raise?' do
    test_subject "[!y1b28] returns exception object." do
      pr = proc { "SOS".sos }
      if RUBY_VERSION >= "3.3"
        expected = "undefined method `sos' for an instance of String"
      elsif RUBY_VERSION =~ /^3\.1\./
        expected = "undefined method `sos' for \"SOS\":String\n"\
                   "\n"\
                   "      pr = proc { \"SOS\".sos }\n"\
                   "                       ^^^^"
      else
        expected = "undefined method `sos' for \"SOS\":String"
      end
      ret = ok {pr}.raise?(NoMethodError, expected)
      test_eq? ret.class, NoMethodError
      test_eq? ret.message, expected
    end
    test_subject "[!2rnni] 1st argument can be error message string or rexp." do
      pr = proc { raise "something wrong" }
      PASS! { ok {pr}.raise?("something wrong") }
      PASS! { ok {pr}.raise?(/something wrong/) }
      #
      pr = proc { raise StandardError, "something wrong" }
      ERROR!(StandardError, "something wrong") { ok {pr}.raise?("something wrong") }
    end
    test_target 'Oktest::AssertionObject[!dpv5g] when `ok{}` called...' do
      test_subject "[!yps62] assertion passes when expected exception raised." do
        pr = proc { "SOS".sub() }
        PASS! { ok {pr}.raise?(ArgumentError) }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(ZeroDivisionError) }
      end
      test_subject "[!wbwdo] raises assertion error when nothing raised." do
        pr = proc { nil }
        errmsg = "Expected ArgumentError to be raised but nothing raised."
        FAIL!(errmsg) { ok {pr}.raise?(ArgumentError) }
      end
      test_subject "[!lq6jv] compares error class with '==' operator, not '.is_a?'." do
        pr = proc { "SOS".foobar }
        PASS! { ok {pr}.raise?(NoMethodError) }
        test_ok? NoMethodError < NameError, msg: "NoMethodError extends NameError"
        ERROR!(NoMethodError, /foobar/) { ok {pr}.raise?(NameError) }
      end
      test_subject "[!hwg0z] compares error class with '.is_a?' if '_subclass: true' specified." do
        pr = proc { "SOS".foobar }
        PASS! { ok {pr}.raise?(NoMethodError, nil) }
        test_ok? NoMethodError < NameError, msg: "NoMethodError extends NameError"
        PASS! { ok {pr}.raise?(NameError, nil, _subclass: true) }
      end
      test_subject "[!4n3ed] reraises if exception is not matched to specified error class." do
        pr = proc { "SOS".sos }
        if RUBY_VERSION >= "3.3"
          errmsg = "undefined method `sos' for an instance of String"
        elsif RUBY_VERSION =~ /^3\.1\./
          errmsg = "undefined method `sos' for \"SOS\":String\n"\
                   "\n"\
                   "        pr = proc { \"SOS\".sos }\n"\
                   "                         ^^^^"
        else
          errmsg = "undefined method `sos' for \"SOS\":String"
        end
        ERROR!(NoMethodError, errmsg) { ok {pr}.raise?(ArgumentError) }
      end
      test_subject "[!tpxlv] accepts string or regexp as error message." do
        if RUBY_VERSION >= "3.1"
          expected = "undefined method `sos' for \"SOS\":String\n"\
                     "\n"\
                     "        pr = proc { \"SOS\".sos }\n"\
                     "                         ^^^^"
        else
          expected = "undefined method `sos' for \"SOS\":String"
        end
        pr = proc { "SOS".sos }
        PASS! { ok {pr}.raise?(NoMethodError, ) }
        pr = proc { "SOS".sos }
        if RUBY_VERSION >= "3.3"
          expected = /^undefined method `sos' for an instance of String$/
        else
          expected = /^undefined method `sos' for "SOS":String$/
        end
        PASS! { ok {pr}.raise?(NoMethodError, expected) }
      end
      test_subject "[!4c6x3] not check exception class when nil specified as errcls." do
        pr = proc { foobar() }
        PASS! { ok {pr}.raise?(nil, /undefined method `foobar'/) }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(nil, "divided by 0") }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(nil) }
      end
      test_subject "[!dq97o] if block given, call test_subject with exception object." do
        pr = proc { "SOS".foobar }
        exc1 = nil
        ok {pr}.raise?(NoMethodError) do |exc2|
          exc1 = exc2
        end
        test_ok? exc1 != nil
        test_ok? exc1.equal?(pr.exc)
      end
    end
    test_target 'Oktest::AssertionObject[!qkr3h] when `ok{}.NOT` called...' do
      test_subject "[!cownv] not support error message." do
        pr = proc { raise "some error" }
        errmsg = "\"some error\": NOT.raise?() can't take errmsg."
        ERROR!(ArgumentError, errmsg) { ok {pr}.NOT.raise?(Exception, "some error") }
      end
      test_subject "[!spzy2] is available with NOT." do
        pr = proc { "SOS".length }
        PASS! { ok {pr}.NOT.raise? }
      end
      test_subject "[!a1a40] assertion passes when nothing raised." do
        pr = proc { nil }
        PASS! { ok {pr}.NOT.raise? }
      end
      test_subject "[!61vtv] assertion fails when specified exception raised." do
        pr = proc { "SOS".foobar }
        if RUBY_VERSION >= "3.3"
          errmsg = "NoMethodError should not be raised but got #<NoMethodError: undefined method `foobar' for an instance of String>."
        elsif RUBY_VERSION =~ /^3\.1\./
          errmsg = "NoMethodError should not be raised but got #<NoMethodError: undefined method `foobar' for \"SOS\":String\n"\
                   "\n"\
                   "        pr = proc { \"SOS\".foobar }\n"\
                   "                         ^^^^^^^>."
        else
          errmsg = "NoMethodError should not be raised but got #<NoMethodError: undefined method `foobar' for \"SOS\":String>."
        end
        FAIL!(errmsg) { ok {pr}.NOT.raise?(NoMethodError) }
      end
      test_subject "[!smprc] compares error class with '==' operator, not '.is_a?'." do
        pr = proc { "SOS".foobar }
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NoMethodError) }
        test_ok? NoMethodError < NameError, msg: "NoMethodError extends NameError"
        ERROR!(NoMethodError) { ok {pr}.NOT.raise?(NameError) }
      end
      test_subject "[!34nd8] compares error class with '.is_a?' if '_subclass: true' specified." do
        pr = proc { "SOS".foobar }
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NoMethodError, nil) }
        test_ok? NoMethodError < NameError, msg: "NoMethodError extends NameError"
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NameError, nil, _subclass: true) }
      end
      test_subject "[!shxne] reraises exception if different from specified error class." do
        pr = proc { 1/0 }
        errmsg = "divided by 0"
        ERROR!(ZeroDivisionError, errmsg) { ok {pr}.NOT.raise?(NoMethodError) }
      end
      test_subject "[!36032] re-raises exception when errcls is nil." do
        pr = proc { foobar() }
        ERROR!(NoMethodError) { ok {pr}.NOT.raise?(nil) }
        pr = proc { 1/0 }
        ERROR!(ZeroDivisionError) { ok {pr}.NOT.raise?(nil) }
      end
    end
    test_subject "[!vnc6b] sets exception object into '#exc' attribute." do
      pr = proc { "SOS".foobar }
      test_ok? !pr.respond_to?(:exc)
      PASS! { ok {pr}.raise?(NoMethodError) }
      test_ok? pr.respond_to?(:exc)
      test_ok? pr.exc.is_a?(NoMethodError)
      if RUBY_VERSION >= "3.3"
        errmsg = "undefined method `foobar' for an instance of String"
      elsif RUBY_VERSION =~ /^3\.1\./
        errmsg = "undefined method `foobar' for \"SOS\":String\n"\
                 "\n"\
                 "      pr = proc { \"SOS\".foobar }\n"\
                 "                       ^^^^^^^"
      else
        errmsg = "undefined method `foobar' for \"SOS\":String"
      end
      test_eq? pr.exc.message, errmsg
      #
      pr = proc { nil }
      test_ok? !pr.respond_to?(:exc)
      PASS! { ok {pr}.NOT.raise?(NoMethodError) }
      test_ok? pr.respond_to?(:exc)
      test_eq? pr.exc, nil
    end
  end

  test_target 'Oktest::AssertionObject#raise!' do
    test_subject "[!8k6ee] compares error class by '.is_a?' instead of '=='." do
      pr = proc { "SOS".foobar }
      PASS! { ok {pr}.raise!(NoMethodError) }
      PASS! { ok {pr}.raise!(NameError) }
      ERROR!(NoMethodError, /foobar/) { ok {pr}.raise?(NameError) }
    end
  end

  test_target 'Oktest::AssertionObject#raise_nothing?' do
    test_subject "[!leqey] do nothing without calling proc object." do
      pr = proc { 1/0 }
      ERROR!(ZeroDivisionError) { ok {pr}.raise_nothing? }
    end
    test_subject "[!a61b7] not available with `.NOT`." do
      pr = proc { nil }
      errmsg = "`raise_nothing?()` is not available with `.NOT`."
      ERROR!(Oktest::OktestError, errmsg) { ok {pr}.NOT.raise_nothing? }
    end
  end

  test_target 'Oktest::AssertionObject#thrown?' do
    test_subject "[!w7935] raises ArgumentError when arg of 'thrown?()' is nil." do
      ERROR!(ArgumentError, "throw?(nil): expected tag required.") do
        pr = proc { throw :sym1 }
        ok {pr}.throw?(nil)
      end
    end
    test_subject "[!lglzr] assertion passes when expected symbol thrown." do
      pr = proc { throw :sym2 }
      ok {pr}.throw?(:sym2)
      test_ok? true, msg: "ok"
    end
    test_subject "[!gf9nx] assertion fails when thrown tag is equal to but not same as expected." do
      pr = proc { throw "sym" }
      expected = ("Thrown tag \"sym\" is equal to but not same as expected.\n"\
                  "    (`\"sym\".equal?(\"sym\")` should be true but not.)")
      FAIL!(expected) { ok {pr}.throw?("sym".dup) }
    end
    test_subject "[!flgwy] assertion fails when thrown tag is different from expectd." do
      FAIL!(":sym4 should be thrown but actually :sym9 thrown.") do
        pr = proc { throw :sym9 }
        ok {pr}.throw?(:sym4)
      end
    end
    test_subject "[!9ik3x] assertion fails when nothing thrown." do
      pr = proc { nil }
      expected = ":sym5 should be thrown but nothing thrown."
      FAIL!(expected) { ok {pr}.throw?(:sym5) }
    end
    test_subject "[!m03vq] raises ArgumentError when non-nil arg passed to 'NOT.thrown?()'." do
      ERROR!(ArgumentError, "NOT.throw?(:sym6): argument should be nil.") do
        pr = proc { nil }
        ok {pr}.NOT.throw?(:sym6)
      end
    end
    test_subject "[!kxizg] assertion fails when something thrown in 'NOT.throw?()'." do
      pr = proc { throw :sym7 }
      expected = "Nothing should be thrown but :sym7 thrown."
      FAIL!(expected) { ok {pr}.NOT.throw?(nil) }
    end
    test_subject "[!zq9h6] returns self when passed." do
      pr = proc { throw :sym8 }
      should_return_self { ok {pr}.throw?(:sym8) }
      #
      pr = proc { nil }
      should_return_self { ok {pr}.NOT.throw?(nil) }
    end
  end

  test_target 'Oktest::AssertionObject#in?' do
    test_subject "[!jzoxg] returns self when passed." do
      should_return_self { ok {3}.in?(1..5) }
    end
    test_subject "[!9rm8g] raises assertion error when failed." do
      errmsg = "$<expected>.include?($<actual>): failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..2"
      FAIL!(errmsg) { ok {3}.in?(1..2) }
    end
    test_subject "[!singl] is available with NOT." do
      PASS! { ok {3}.NOT.in?(1..2) }
      errmsg = "$<expected>.include?($<actual>) == false: failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..5"
      FAIL!(errmsg) { ok {3}.NOT.in?(1..5) }
    end
  end

  test_target 'Oktest::AssertionObject#attr()' do
    test_subject "[!lz3lb] returns self when passed." do
      should_return_self { ok {"SOS"}.attr(:length, 3) }
    end
    test_subject "[!79tgn] raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {"SOS"}.attr(:size, 2) }
    end
    test_subject "[!cqnu3] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.attr(:length, 2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {"SOS"}.NOT.attr(:size, 3) }
    end
  end

  test_target 'Oktest::AssertionObject#attrs()' do
    test_subject "[!rtq9f] returns self when passed." do
      should_return_self { ok {"SOS"}.attrs(:length=>3, :size=>3) }
    end
    test_subject "[!7ta0s] raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {"SOS"}.attrs(:size=>2) }
    end
    test_subject "[!s0pnk] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.attrs(:length=>2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {"SOS"}.NOT.attrs(:size=>3) }
    end
  end

  test_target 'Oktest::AssertionObject#keyval()' do
    test_subject "[!byebv] returns self when passed." do
      d = {'a'=>1}
      should_return_self { ok {d}.keyval('a', 1) }
    end
    test_subject "[!vtrlz] raises assertion error when failed." do
      d = {'a'=>1}
      errmsg = "$<actual>[\"a\"] == $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: \"1\""
      FAIL!(errmsg) { ok {d}.keyval('a', '1') }
    end
    test_subject "[!mmpwz] is available with NOT." do
      d = {'a'=>1}
      PASS! { ok {d}.NOT.keyval('a', '1') }
      errmsg = "$<actual>[\"a\"] != $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: 1"
      FAIL!(errmsg) { ok {d}.NOT.keyval('a', 1) }
    end
  end

  test_target 'Oktest::AssertionObject#keyvals()' do
    test_subject "[!vtw22] returns self when passed." do
      d = {'a'=>1, 'b'=>2}
      should_return_self { ok {d}.keyvals('a'=>1, 'b'=>2) }
    end
    test_subject "[!fyvmn] raises assertion error when failed." do
      d = {'a'=>1, 'b'=>2}
      errmsg = "$<actual>[\"a\"] == $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: \"1\""
      FAIL!(errmsg) { ok {d}.keyvals('a'=>'1', 'b'=>2) }
    end
    test_subject "[!js2j2] is available with NOT." do
      d = {'a'=>1, 'b'=>2}
      PASS! { ok {d}.NOT.keyvals('a'=>'1') }
      errmsg = "$<actual>[\"a\"] != $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: 1"
      FAIL!(errmsg) { ok {d}.NOT.keyvals('a'=>1) }
    end
  end

  test_target 'Oktest::AssertionObject#length' do
    test_subject "[!l9vnv] returns self when passed." do
      should_return_self { ok {"SOS"}.length(3) }
    end
    test_subject "[!1y787] raises assertion error when failed." do
      errmsg = "$<actual>.length == 5: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.length(5) }
    end
    test_subject "[!kryx2] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.length(5) }
      errmsg = "$<actual>.length != 3: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.NOT.length(3) }
    end
  end

  test_target 'Oktest::AssertionObject#truthy?' do
    test_subject "[!nhmuk] returns self when passed." do
      should_return_self { ok {""}.truthy? }
    end
    test_subject "[!3d94h] raises assertion error when failed." do
      errmsg = "!!$<actual> == true: failed.\n"\
               "    $<actual>:   nil"
      FAIL!(errmsg) { ok {nil}.truthy? }
    end
    test_subject "[!8rmgp] is available with NOT." do
      PASS! { ok {nil}.NOT.truthy? }
      errmsg = "!!$<actual> != true: failed.\n"\
               "    $<actual>:   0"
      FAIL!(errmsg) { ok {0}.NOT.truthy? }
    end
  end

  test_target 'Oktest::AssertionObject#falsy?' do
    test_subject "[!w1vm6] returns self when passed." do
      should_return_self { ok {nil}.falsy? }
    end
    test_subject "[!7o48g] raises assertion error when failed." do
      errmsg = "!!$<actual> == false: failed.\n"\
               "    $<actual>:   0"
      FAIL!(errmsg) { ok {0}.falsy? }
    end
    test_subject "[!i44q6] is available with NOT." do
      PASS! { ok {0}.NOT.falsy? }
      errmsg = "!!$<actual> != false: failed.\n"\
               "    $<actual>:   nil"
      FAIL!(errmsg) { ok {nil}.NOT.falsy? }
    end
  end

  test_target 'Oktest::AssertionObject#file_exist?' do
    test_subject "[!6bcpp] returns self when passed." do
      should_return_self { ok {__FILE__}.file_exist? }
    end
    test_subject "[!69bs0] raises assertion error when failed." do
      errmsg = "File.file?($<actual>): failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.file_exist? }
    end
    test_subject "[!r1mze] is available with NOT." do
      PASS! { ok {'.'}.NOT.file_exist? }
      errmsg = "File.file?($<actual>) == false: failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      FAIL!(errmsg) { ok {__FILE__}.NOT.file_exist? }
    end
  end

  test_target 'Oktest::AssertionObject#dir_exist?' do
    test_subject "[!8qe7u] returns self when passed." do
      should_return_self { ok {'.'}.dir_exist? }
    end
    test_subject "[!vfh7a] raises assertion error when failed." do
      errmsg = "File.directory?($<actual>): failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      FAIL!(errmsg) { ok {__FILE__}.dir_exist? }
    end
    test_subject "[!qtllp] is available with NOT." do
      PASS! { ok {__FILE__}.NOT.dir_exist? }
      errmsg = "File.directory?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.NOT.dir_exist? }
    end
  end

  test_target 'Oktest::AssertionObject#symlink_exist?' do
    def self.with_symlink(&b)
      linkname = "_sym_#{rand().to_s[2...7]}"
      File.symlink(__FILE__, linkname)
      b.call linkname
    ensure
      File.unlink(linkname)
    end
    test_subject "[!ugfi3] returns self when passed." do
      with_symlink do |linkname|
        should_return_self { ok {linkname}.symlink_exist? }
      end
    end
    test_subject "[!qwngl] raises assertion error when failed." do
      with_symlink do |linkname|
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \"_not_exist\""
        FAIL!(errmsg) { ok {'_not_exist'}.symlink_exist? }
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \".\""
        FAIL!(errmsg) { ok {'.'}.symlink_exist? }
      end
    end
    test_subject "[!cgpbt] is available with NOT." do
      with_symlink do |linkname|
        PASS! { ok {'_not_exist'}.NOT.symlink_exist? }
        PASS! { ok {'.'}.NOT.symlink_exist? }
        errmsg = "File.symlink?($<actual>) == false: failed.\n"\
                 "    $<actual>:   \"#{linkname}\""
        FAIL!(errmsg) { ok {linkname}.NOT.symlink_exist? }
      end
    end
  end

  test_target 'Oktest::AssertionObject#not_exist?' do
    test_subject "[!1ujag] returns self when passed." do
      should_return_self { ok {'_not_exist'}.not_exist? }
    end
    test_subject "[!ja84s] raises assertion error when failed." do
      errmsg = "File.exist?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.not_exist? }
    end
    test_subject "[!to5z3] is available with NOT." do
      PASS! { ok {'.'}.NOT.not_exist? }
      errmsg = "File.exist?($<actual>): failed.\n"\
               "    $<actual>:   \"_not_exist\""
      FAIL!(errmsg) { ok {'_not_exist'}.NOT.not_exist? }
    end
  end

  test_target 'Oktest::AssertionObject#JSON()' do
    test_subject "[!n0k03] creates JsonMatcher object." do
      o = JSON({})
      test_eq? o.class, Oktest::JsonMatcher
    end
  end

  test_target 'Oktest::AssertionObject#Enum()' do
    test_subject "[!fbfr0] creates Enum object which is a subclass of Set." do
      o = Enum("a", "b", "c")
      test_eq? o.class, Oktest::JsonMatcher::Enum
      test_ok?  o.class < Set
      test_eq? (o === "a"), true
      test_eq? (o === "b"), true
      test_eq? (o === "c"), true
      test_eq? (o === "d"), false
    end
  end

  test_target 'Oktest::AssertionObject#Bool()' do
    test_subject "[!vub5j] creates a set of true and false." do
      test_eq? Bool().class, Oktest::JsonMatcher::Enum
      test_ok? Bool() === true
      test_ok? Bool() === false
      test_eq? (Bool() === 1), false
      test_eq? (Bool() === 0), false
    end
  end

  test_target 'Oktest::AssertionObject#OR()' do
    test_subject "[!9e8im] creates `OR` object." do
      o = OR(1, 2, 3)
      test_eq? o.class, Oktest::JsonMatcher::OR
    end
  end

  test_target 'Oktest::AssertionObject#AND()' do
    test_subject "[!38jln] creates `AND` object." do
      o = AND(4, 5, 6)
      test_eq? o.class, Oktest::JsonMatcher::AND
    end
  end

  test_target 'Oktest::AssertionObject#Length()' do
    test_subject "[!qqas3] creates Length object." do
      o = Length(3)
      test_eq? o.class, Oktest::JsonMatcher::Length
    end
  end

  test_target 'Oktest::AssertionObject#Any()' do
    test_subject "[!dlo1o] creates an 'Any' object." do
      test_eq? Any().class, Oktest::JsonMatcher::Any
    end
  end

end
