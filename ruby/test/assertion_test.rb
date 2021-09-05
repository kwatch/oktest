# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class AssertionObject_TC < TC
  #include Test::Unit::Assertions
  include Oktest::SpecHelper

  def FAIL!(errmsg, &b)
    failmsg = "expected to be failed, but succeeded unexpectedly."
    return ERROR!(Oktest::FAIL_EXCEPTION, errmsg, failmsg, &b)
  end

  def ERROR!(errcls, errmsg=nil, _failmsg=nil, &b)
    exc = nil
    begin
      yield
    rescue Exception => exc_
      exc = exc_
      errcls == exc_.class or
        raise
    else
      _failmsg ||= "#{errcls} expected to be raised, but nothing raised."
      assert false, _failmsg
    end
    #
    if errmsg
      assert errmsg === exc.message,
        ("unexpected error message:\n"\
         "  expected: #{errmsg}\n"\
         "  actual:   #{exc.message}")
    end
    #
    return exc
  end

  def PASS!()
    yield
  end

  def should_return_self
    obj = yield
    assert obj.class == Oktest::AssertionObject
  end


  describe '.report_not_yet()' do
    it "[!3nksf] reports if 'ok{}' called but assertion not performed." do
      assert Oktest::AssertionObject::NOT_YET.empty?, "should be empty"
      sout, serr = capture do
        Oktest::AssertionObject.report_not_yet()
      end
      assert_eq sout, ""
      assert_eq serr, ""
      #
      lineno = __LINE__ + 1
      ok {1+1}
      assert ! Oktest::AssertionObject::NOT_YET.empty?, "should not be empty"
      sout, serr = capture { Oktest::AssertionObject.report_not_yet() }
      expected = "** warning: ok() is called but not tested yet (at #{__FILE__}:#{lineno}:in"
      assert_eq sout, ""
      assert serr.start_with?(expected), "not matched"
    end
    it "[!f92q4] clears remained objects." do
      ok {1+1}
      assert ! Oktest::AssertionObject::NOT_YET.empty?, "should not be empty"
      sout, serr = capture { Oktest::AssertionObject.report_not_yet() }
      assert Oktest::AssertionObject::NOT_YET.empty?, "should be empty"
    end
  end

  describe '.NOT()' do
    it "[!g775v] returns self." do
      begin
        should_return_self { ok {1+1}.NOT }
      ensure
        Oktest::AssertionObject::NOT_YET.clear()
      end
    end
    it "[!63dde] toggles internal boolean." do
      begin
        x = ok {1+1}
        assert_eq x.bool, true
        x.NOT
        assert_eq x.bool, false
      ensure
        Oktest::AssertionObject::NOT_YET.clear()
      end
    end
  end

  describe '#==' do
    it "[!c6p0e] returns self when passed." do
      should_return_self { ok {1+1} == 2 }
    end
    it "[!1iun4] raises assertion error when failed." do
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {1+1} == 3 }
    end
    it "[!eyslp] is avaialbe with NOT." do
      PASS! { ok {1+1}.NOT == 3 }
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {1+1}.NOT == 2 }
    end
    it "[!3xnqv] shows context diff when both actual and expected are text." do
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

  describe '#!=' do
    it "[!iakbb] returns self when passed." do
      should_return_self { ok {1+1} != 3 }
    end
    it "[!90tfb] raises assertion error when failed." do
      #errmsg = "<2> expected to be != to\n<2>."
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {1+1} != 2 }
    end
    it "[!l6afg] is avaialbe with NOT." do
      PASS! { ok {1+1}.NOT != 2 }
      #errmsg = "<3> expected but was\n<2>."
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {1+1}.NOT != 3 }
    end
  end #if RUBY_VERSION >= "1.9"

  describe '#===' do
    it "[!uh8bm] returns self when passed." do
      should_return_self { ok {String} === 'str' }
    end
    it "[!42f6a] raises assertion error when failed." do
      errmsg = "$<actual> === $<expected>: failed.\n"\
               "    $<actual>:   Integer\n"\
               "    $<expected>: \"str\""
      FAIL!(errmsg) { ok {Integer} === 'str' }
    end
    it "[!vhvyu] is avaialbe with NOT." do
      PASS! { ok {Integer}.NOT === 'str' }
      errmsg = "!($<actual> === $<expected>): failed.\n"\
               "    $<actual>:   String\n"\
               "    $<expected>: \"str\""
      FAIL!(errmsg) { ok {String}.NOT === 'str' }
    end
    it "[!mjh4d] raises error when combination of 'not_ok()' and matcher object." do
      errmsg = "negative `===` is not available with matcher object."
      assert_exc(Oktest::OktestError, errmsg) do
        not_ok {Oktest::JsonMatcher.new({})} === {}
      end
      assert_exc(Oktest::OktestError, errmsg) do
        ok {Oktest::JsonMatcher.new({})}.NOT === {}
      end
    end
  end

  describe '>' do
    it "[!3j7ty] returns self when passed." do
      should_return_self { ok {2} > 1 }
    end
    it "[!vjjuq] raises assertion error when failed." do
      #errmsg = "Expected 2 to be > 2."
      errmsg = "2 > 2: failed."
      FAIL!(errmsg) { ok {2} > 2 }
      errmsg = "1 > 2: failed."
      FAIL!(errmsg) { ok {1} > 2 }
      #
      errmsg = "\"aaa\" > \"bbb\": failed."
      FAIL!(errmsg) { ok {'aaa'} > 'bbb' }
    end
    it "[!73a0t] is avaialbe with NOT." do
      PASS! { ok {2}.NOT > 2 }
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      FAIL!(errmsg) { ok {2}.NOT > 1 }
    end
  end

  describe '>=' do
    it "[!75iqw] returns self when passed." do
      should_return_self { ok {2} >= 2 }
      should_return_self { ok {2} >= 1 }
    end
    it "[!isdfc] raises assertion error when failed." do
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      FAIL!(errmsg) { ok {1} >= 2 }
      #
      errmsg = "\"aaa\" >= \"bbb\": failed."
      FAIL!(errmsg) { ok {'aaa'} >= 'bbb' }
    end
    it "[!3dgmh] is avaialbe with NOT." do
      PASS! { ok {1}.NOT >= 2 }
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      FAIL!(errmsg) { ok {2}.NOT >= 2 }
    end
  end

  describe '<' do
    it "[!vkwcc] returns self when passed." do
      should_return_self { ok {1} < 2 }
    end
    it "[!ukqa0] raises assertion error when failed." do
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      FAIL!(errmsg) { ok {2} < 2 }
      errmsg = "2 < 1: failed."
      FAIL!(errmsg) { ok {2} < 1 }
      #
      errmsg = "\"bbb\" < \"aaa\": failed."
      FAIL!(errmsg) { ok {'bbb'} < 'aaa' }
    end
    it "[!gwvdl] is avaialbe with NOT." do
      PASS! { ok {2}.NOT < 2 }
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      FAIL!(errmsg) { ok {1}.NOT < 2 }
    end
  end

  describe '<=' do
    it "[!yk7t2] returns self when passed." do
      should_return_self { ok {1} <= 2 }
      should_return_self { ok {1} <= 1 }
    end
    it "[!ordwe] raises assertion error when failed." do
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      FAIL!(errmsg) { ok {2} <= 1 }
      #
      errmsg = "\"bbb\" <= \"aaa\": failed."
      FAIL!(errmsg) { ok {'bbb'} <= 'aaa' }
    end
    it "[!mcb9w] is avaialbe with NOT." do
      PASS! { ok {2}.NOT <= 1 }
      #errmsg = "Expected 1 to be > 2."
      errmsg = "1 > 2: failed."
      FAIL!(errmsg) { ok {1}.NOT <= 2 }
    end
  end

  describe '=~' do
    it "[!acypf] returns self when passed." do
      should_return_self { ok {'SOS'} =~ /^[A-Z]+$/ }
    end
    it "[!xkldu] raises assertion error when failed." do
      #errmsg = 'Expected /^\\d+$/ to match "SOS".'
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /^\\d+$/\n"\
               "    $<actual>:   <<'END'\n"\
               "SOS\n"\
               "END\n"
      FAIL!(errmsg) { ok {"SOS\n"} =~ /^\d+$/ }
    end
    it "[!2aa6f] is avaialbe with NOT." do
      PASS! { ok {'SOS'}.NOT =~ /^\d+$/ }
      #errmsg = "</\\w+/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /\\w+/\n"\
               "    $<actual>:   \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'}.NOT =~ /\w+/ }
    end if false
  end

  describe '!~' do
    it "[!xywdr] returns self when passed." do
      should_return_self { ok {'SOS'} !~ /^\d+$/ }
    end
    it "[!58udu] raises assertion error when failed." do
      #errmsg = "</^\\w+$/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /^\\w+$/\n"\
               "    $<actual>:   \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'} !~ /^\w+$/ }
    end
    it "[!iuf5j] is avaialbe with NOT." do
      PASS! { ok {'SOS'}.NOT !~ /^\w+$/ }
      #errmsg = "Expected /\\d+/ to match \"SOS\"."
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /\\d+/\n"\
               "    $<actual>:   <<'END'\nSOS\nEND\n"
      FAIL!(errmsg) { ok {"SOS\n"}.NOT !~ /\d+/ }
    end
  end #if RUBY_VERSION >= "1.9"

  describe '#in_delta?' do
    it "[!m0791] returns self when passed." do
      should_return_self { ok {3.14159}.in_delta?(3.141, 0.001) }
    end
    it "[!f3zui] raises assertion error when failed." do
      errmsg = "($<actual> - $<expected>).abs < #{0.1}: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      FAIL!(errmsg) { ok {1.375}.in_delta?(1.5, 0.1) }
    end
    it "[!t7liw] is avaialbe with NOT." do
      PASS! { ok {1.375}.NOT.in_delta?(1.5, 0.1) }
      errmsg = "($<actual> - $<expected>).abs < #{0.2} == false: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      FAIL!(errmsg) { ok {1.375}.NOT.in_delta?(1.5, 0.2) }
    end
  end

  describe '#same?' do
    it "[!yk7zo] returns self when passed." do
      should_return_self { ok {:SOS}.same?(:SOS) }
    end
    it "[!ozbf4] raises assertion error when failed." do
      errmsg = "$<actual>.equal?($<expected>): failed.\n"\
               "    $<actual>:   \"SOS\"\n"\
               "    $<expected>: \"SOS\"\n"
      FAIL!(errmsg) { ok {'SOS'}.same?('SOS') }
    end
    it "[!dwtig] is avaialbe with NOT." do
      PASS! { ok {'SOS'}.NOT.same? 'SOS' }
      errmsg = "$<actual>.equal?($<expected>) == false: failed.\n"\
               "    $<actual>:   :SOS\n"\
               "    $<expected>: :SOS\n"
      FAIL!(errmsg) { ok {:SOS}.NOT.same?(:SOS) }
    end
  end

describe '#method_missing()' do
    it "[!7bbrv] returns self when passed." do
      should_return_self { ok {"file.png"}.end_with?(".png") }
    end
    it "[!yjnxb] enables to handle boolean methods." do
      PASS! { ok {""}.empty?  }
      PASS! { ok {nil}.nil?  }
      PASS! { ok {1}.is_a?(Integer)  }
    end
    it "[!ttow6] raises NoMethodError when not a boolean method." do
      ERROR!(NoMethodError) do
        ok {"a"}.start_with
      end
    end
    it "[!f0ekh] skip top of backtrace when NoMethodError raised." do
      exc = ERROR!(NoMethodError) do
        ok {[1]}.start_with?(1)
      end
      assert exc.backtrace[0] !~ /\/oktest\.rbc?:/, "backtrace not skipped"
      assert exc.backtrace[0].start_with?(__FILE__), "backtrace not skipped"
    end
    it "[!cun59] fails when boolean method failed returned false." do
      errmsg = "$<actual>.empty?: failed.\n    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.empty? }
      errmsg = "$<actual>.nil?: failed.\n    $<actual>:   \"\""
      FAIL!(errmsg) { ok {""}.nil? }
      errmsg = "$<actual>.is_a?(Integer): failed.\n    $<actual>:   3.14"
      FAIL!(errmsg) { ok {3.14}.is_a?(Integer) }
    end
    it "[!4objh] is available with NOT." do
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
    it "[!sljta] raises TypeError when boolean method returned non-boolean value." do
      errmsg = "ok(): String#sos?() expected to return true or false, but got 1."
      ERROR!(TypeError, errmsg) do
        s = "SOS"
        def s.sos?; return 1; end
        ok {s}.sos?
      end
    end
  end

  describe '#raise?' do
    it "[!y1b28] returns self when passed." do
      pr = proc { "SOS".sos }
      should_return_self { ok {pr}.raise?(NoMethodError, "undefined method `sos' for \"SOS\":String")  }
    end
    it "[!2rnni] 1st argument can be error message string or rexp." do
      pr = proc { raise "something wrong" }
      PASS! { ok {pr}.raise?("something wrong") }
      PASS! { ok {pr}.raise?(/something wrong/) }
      #
      pr = proc { raise StandardError, "something wrong" }
      ERROR!(StandardError, "something wrong") { ok {pr}.raise?("something wrong") }
    end
    describe '[!dpv5g] when `ok{}` called...' do
      it "[!yps62] assertion passes when expected exception raised." do
        pr = proc { "SOS".sub() }
        PASS! { ok {pr}.raise?(ArgumentError) }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(ZeroDivisionError) }
      end
      it "[!wbwdo] raises assertion error when nothing raised." do
        pr = proc { nil }
        errmsg = "Expected ArgumentError to be raised but nothing raised."
        FAIL!(errmsg) { ok {pr}.raise?(ArgumentError) }
      end
      it "[!lq6jv] compares error class with '==' operator, not '.is_a?'." do
        pr = proc { "SOS".foobar }
        PASS! { ok {pr}.raise?(NoMethodError) }
        assert NoMethodError < NameError, "NoMethodError extends NameError"
        ERROR!(NoMethodError, /foobar/) { ok {pr}.raise?(NameError) }
      end
      it "[!hwg0z] compares error class with '.is_a?' if 'subclass: true' specified." do
        pr = proc { "SOS".foobar }
        PASS! { ok {pr}.raise?(NoMethodError, nil) }
        assert NoMethodError < NameError, "NoMethodError extends NameError"
        PASS! { ok {pr}.raise?(NameError, nil, subclass: true) }
      end
      it "[!4n3ed] reraises if exception is not matched to specified error class." do
        pr = proc { "SOS".sos }
        errmsg = "undefined method `sos' for \"SOS\":String"
        ERROR!(NoMethodError, errmsg) { ok {pr}.raise?(ArgumentError) }
      end
      it "[!tpxlv] accepts string or regexp as error message." do
        pr = proc { "SOS".sos }
        PASS! { ok {pr}.raise?(NoMethodError, "undefined method `sos' for \"SOS\":String") }
        pr = proc { "SOS".sos }
        PASS! { ok {pr}.raise?(NoMethodError, /^undefined method `sos' for "SOS":String$/) }
      end
      it "[!4c6x3] not check exception class when nil specified as errcls." do
        pr = proc { foobar() }
        PASS! { ok {pr}.raise?(nil, /undefined method `foobar'/) }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(nil, "divided by 0") }
        pr = proc { 1/0 }
        PASS! { ok {pr}.raise?(nil) }
      end
      it "[!dq97o] if block given, call it with exception object." do
        pr = proc { "SOS".foobar }
        exc1 = nil
        ok {pr}.raise?(NoMethodError) do |exc2|
          exc1 = exc2
        end
        assert exc1 != nil
        assert exc1.equal?(pr.exc)
      end
    end
    describe '[!qkr3h] when `ok{}.NOT` called...' do
      it "[!cownv] not support error message." do
        pr = proc { raise "some error" }
        errmsg = "\"some error\": NOT.raise?() can't take errmsg."
        ERROR!(ArgumentError, errmsg) { ok {pr}.NOT.raise?(Exception, "some error") }
      end
      it "[!spzy2] is available with NOT." do
        pr = proc { "SOS".length }
        PASS! { ok {pr}.NOT.raise? }
      end
      it "[!a1a40] assertion passes when nothing raised." do
        pr = proc { nil }
        PASS! { ok {pr}.NOT.raise? }
      end
      it "[!61vtv] assertion fails when specified exception raised." do
        pr = proc { "SOS".foobar }
        errmsg = "NoMethodError should not be raised but got #<NoMethodError: undefined method `foobar' for \"SOS\":String>."
        FAIL!(errmsg) { ok {pr}.NOT.raise?(NoMethodError) }
      end
      it "[!smprc] compares error class with '==' operator, not '.is_a?'." do
        pr = proc { "SOS".foobar }
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NoMethodError) }
        assert NoMethodError < NameError, "NoMethodError extends NameError"
        ERROR!(NoMethodError) { ok {pr}.NOT.raise?(NameError) }
      end
      it "[!34nd8] compares error class with '.is_a?' if 'subclass: true' specified." do
        pr = proc { "SOS".foobar }
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NoMethodError, nil) }
        assert NoMethodError < NameError, "NoMethodError extends NameError"
        FAIL!(/foobar/) { ok {pr}.NOT.raise?(NameError, nil, subclass: true) }
      end
      it "[!shxne] reraises exception if different from specified error class." do
        pr = proc { 1/0 }
        errmsg = "divided by 0"
        ERROR!(ZeroDivisionError, errmsg) { ok {pr}.NOT.raise?(NoMethodError) }
      end
      it "[!36032] re-raises exception when errcls is nil." do
        pr = proc { foobar() }
        ERROR!(NoMethodError) { ok {pr}.NOT.raise?(nil) }
        pr = proc { 1/0 }
        ERROR!(ZeroDivisionError) { ok {pr}.NOT.raise?(nil) }
      end
    end
    it "[!vnc6b] sets exception object into '#exc' attribute." do
      pr = proc { "SOS".foobar }
      assert !pr.respond_to?(:exc)
      PASS! { ok {pr}.raise?(NoMethodError) }
      assert pr.respond_to?(:exc)
      assert pr.exc.is_a?(NoMethodError)
      assert_eq pr.exc.message, "undefined method `foobar' for \"SOS\":String"
      #
      pr = proc { nil }
      assert !pr.respond_to?(:exc)
      PASS! { ok {pr}.NOT.raise?(NoMethodError) }
      assert pr.respond_to?(:exc)
      assert_eq pr.exc, nil
    end
  end

  describe '#raise!' do
    it "[!8k6ee] compares error class by '.is_a?' instead of '=='." do
      pr = proc { "SOS".foobar }
      PASS! { ok {pr}.raise!(NoMethodError) }
      PASS! { ok {pr}.raise!(NameError) }
      ERROR!(NoMethodError, /foobar/) { ok {pr}.raise?(NameError) }
    end
  end

  describe '#thrown?' do
    it "[!w7935] raises ArgumentError when arg of 'thrown?()' is nil." do
      ERROR!(ArgumentError, "throw?(nil): expected tag required.") do
        pr = proc { throw :sym1 }
        ok {pr}.throw?(nil)
      end
    end
    it "[!lglzr] assertion passes when expected symbol thrown." do
      pr = proc { throw :sym2 }
      ok {pr}.throw?(:sym2)
      assert true, "ok"
    end
    it "[!gf9nx] assertion fails when thrown tag is equal to but not same as expected." do
      pr = proc { throw "sym" }
      expected = ("Thrown tag \"sym\" is equal to but not same as expected.\n"\
                  "    (`\"sym\".equal?(\"sym\")` should be true but not.)")
      FAIL!(expected) { ok {pr}.throw?("sym") }
    end
    it "[!flgwy] assertion fails when thrown tag is different from expectd." do
      FAIL!(":sym4 should be thrown but actually :sym9 thrown.") do
        pr = proc { throw :sym9 }
        ok {pr}.throw?(:sym4)
      end
    end
    it "[!9ik3x] assertion fails when nothing thrown." do
      pr = proc { nil }
      expected = ":sym5 should be thrown but nothing thrown."
      FAIL!(expected) { ok {pr}.throw?(:sym5) }
    end
    it "[!m03vq] raises ArgumentError when non-nil arg passed to 'NOT.thrown?()'." do
      ERROR!(ArgumentError, "NOT.throw?(:sym6): argument should be nil.") do
        pr = proc { nil }
        ok {pr}.NOT.throw?(:sym6)
      end
    end
    it "[!kxizg] assertion fails when something thrown in 'NOT.throw?()'." do
      pr = proc { throw :sym7 }
      expected = "Nothing should be thrown but :sym7 thrown."
      FAIL!(expected) { ok {pr}.NOT.throw?(nil) }
    end
    it "[!zq9h6] returns self when passed." do
      pr = proc { throw :sym8 }
      should_return_self { ok {pr}.throw?(:sym8) }
      #
      pr = proc { nil }
      should_return_self { ok {pr}.NOT.throw?(nil) }
    end
  end

  describe '#in?' do
    it "[!jzoxg] returns self when passed." do
      should_return_self { ok {3}.in?(1..5) }
    end
    it "[!9rm8g] raises assertion error when failed." do
      errmsg = "$<expected>.include?($<actual>): failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..2"
      FAIL!(errmsg) { ok {3}.in?(1..2) }
    end
    it "[!singl] is available with NOT." do
      PASS! { ok {3}.NOT.in?(1..2) }
      errmsg = "$<expected>.include?($<actual>) == false: failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..5"
      FAIL!(errmsg) { ok {3}.NOT.in?(1..5) }
    end
  end

  describe '#attr()' do
    it "[!lz3lb] returns self when passed." do
      should_return_self { ok {"SOS"}.attr(:length, 3) }
    end
    it "[!79tgn] raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {"SOS"}.attr(:size, 2) }
    end
    it "[!cqnu3] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.attr(:length, 2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {"SOS"}.NOT.attr(:size, 3) }
    end
  end

  describe '#attrs()' do
    it "[!rtq9f] returns self when passed." do
      should_return_self { ok {"SOS"}.attrs(:length=>3, :size=>3) }
    end
    it "[!7ta0s] raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      FAIL!(errmsg) { ok {"SOS"}.attrs(:size=>2) }
    end
    it "[!s0pnk] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.attrs(:length=>2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      FAIL!(errmsg) { ok {"SOS"}.NOT.attrs(:size=>3) }
    end
  end

  describe '#keyval()' do
    it "[!byebv] returns self when passed." do
      d = {'a'=>1}
      should_return_self { ok {d}.keyval('a', 1) }
    end
    it "[!vtrlz] raises assertion error when failed." do
      d = {'a'=>1}
      errmsg = "$<actual>[\"a\"] == $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: \"1\""
      FAIL!(errmsg) { ok {d}.keyval('a', '1') }
    end
    it "[!mmpwz] is available with NOT." do
      d = {'a'=>1}
      PASS! { ok {d}.NOT.keyval('a', '1') }
      errmsg = "$<actual>[\"a\"] != $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: 1"
      FAIL!(errmsg) { ok {d}.NOT.keyval('a', 1) }
    end
  end

  describe '#keyvals()' do
    it "[!vtw22] returns self when passed." do
      d = {'a'=>1, 'b'=>2}
      should_return_self { ok {d}.keyvals('a'=>1, 'b'=>2) }
    end
    it "[!fyvmn] raises assertion error when failed." do
      d = {'a'=>1, 'b'=>2}
      errmsg = "$<actual>[\"a\"] == $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: \"1\""
      FAIL!(errmsg) { ok {d}.keyvals('a'=>'1', 'b'=>2) }
    end
    it "[!js2j2] is available with NOT." do
      d = {'a'=>1, 'b'=>2}
      PASS! { ok {d}.NOT.keyvals('a'=>'1') }
      errmsg = "$<actual>[\"a\"] != $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: 1"
      FAIL!(errmsg) { ok {d}.NOT.keyvals('a'=>1) }
    end
  end

  describe '#length' do
    it "[!l9vnv] returns self when passed." do
      should_return_self { ok {"SOS"}.length(3) }
    end
    it "[!1y787] raises assertion error when failed." do
      errmsg = "$<actual>.length == 5: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.length(5) }
    end
    it "[!kryx2] is available with NOT." do
      PASS! { ok {"SOS"}.NOT.length(5) }
      errmsg = "$<actual>.length != 3: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      FAIL!(errmsg) { ok {"SOS"}.NOT.length(3) }
    end
  end

  describe '#truthy?' do
    it "[!nhmuk] returns self when passed." do
      should_return_self { ok {""}.truthy? }
    end
    it "[!3d94h] raises assertion error when failed." do
      errmsg = "!!$<actual> == true: failed.\n"\
               "    $<actual>:   nil"
      FAIL!(errmsg) { ok {nil}.truthy? }
    end
    it "[!8rmgp] is available with NOT." do
      PASS! { ok {nil}.NOT.truthy? }
      errmsg = "!!$<actual> != true: failed.\n"\
               "    $<actual>:   0"
      FAIL!(errmsg) { ok {0}.NOT.truthy? }
    end
  end

  describe '#falsy?' do
    it "[!w1vm6] returns self when passed." do
      should_return_self { ok {nil}.falsy? }
    end
    it "[!7o48g] raises assertion error when failed." do
      errmsg = "!!$<actual> == false: failed.\n"\
               "    $<actual>:   0"
      FAIL!(errmsg) { ok {0}.falsy? }
    end
    it "[!i44q6] is available with NOT." do
      PASS! { ok {0}.NOT.falsy? }
      errmsg = "!!$<actual> != false: failed.\n"\
               "    $<actual>:   nil"
      FAIL!(errmsg) { ok {nil}.NOT.falsy? }
    end
  end

  describe '#file_exist?' do
    it "[!6bcpp] returns self when passed." do
      should_return_self { ok {__FILE__}.file_exist? }
    end
    it "[!69bs0] raises assertion error when failed." do
      errmsg = "File.file?($<actual>): failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.file_exist? }
    end
    it "[!r1mze] is available with NOT." do
      PASS! { ok {'.'}.NOT.file_exist? }
      errmsg = "File.file?($<actual>) == false: failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      FAIL!(errmsg) { ok {__FILE__}.NOT.file_exist? }
    end
  end

  describe '#dir_exist?' do
    it "[!8qe7u] returns self when passed." do
      should_return_self { ok {'.'}.dir_exist? }
    end
    it "[!vfh7a] raises assertion error when failed." do
      errmsg = "File.directory?($<actual>): failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      FAIL!(errmsg) { ok {__FILE__}.dir_exist? }
    end
    it "[!qtllp] is available with NOT." do
      PASS! { ok {__FILE__}.NOT.dir_exist? }
      errmsg = "File.directory?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.NOT.dir_exist? }
    end
  end

  describe '#symlink_exist?' do
    def with_symlink
      linkname = "_sym_#{rand().to_s[2...7]}"
      File.symlink(__FILE__, linkname)
      yield linkname
    ensure
      File.unlink(linkname)
    end
    it "[!ugfi3] returns self when passed." do
      with_symlink do |linkname|
        should_return_self { ok {linkname}.symlink_exist? }
      end
    end
    it "[!qwngl] raises assertion error when failed." do
      with_symlink do |linkname|
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \"_not_exist\""
        FAIL!(errmsg) { ok {'_not_exist'}.symlink_exist? }
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \".\""
        FAIL!(errmsg) { ok {'.'}.symlink_exist? }
      end
    end
    it "[!cgpbt] is available with NOT." do
      with_symlink do |linkname|
        PASS! { ok {'_not_exist'}.NOT.symlink_exist? }
        PASS! { ok {'.'}.NOT.symlink_exist? }
        errmsg = "File.symlink?($<actual>) == false: failed.\n"\
                 "    $<actual>:   \"#{linkname}\""
        FAIL!(errmsg) { ok {linkname}.NOT.symlink_exist? }
      end
    end
  end

  describe '#not_exist?' do
    it "[!1ujag] returns self when passed." do
      should_return_self { ok {'_not_exist'}.not_exist? }
    end
    it "[!ja84s] raises assertion error when failed." do
      errmsg = "File.exist?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      FAIL!(errmsg) { ok {'.'}.not_exist? }
    end
    it "[!to5z3] is available with NOT." do
      PASS! { ok {'.'}.NOT.not_exist? }
      errmsg = "File.exist?($<actual>): failed.\n"\
               "    $<actual>:   \"_not_exist\""
      FAIL!(errmsg) { ok {'_not_exist'}.NOT.not_exist? }
    end
  end

  describe '#JSON()' do
    it "[!n0k03] creates JsonMatcher object." do
      o = JSON({})
      assert_eq o.class, Oktest::JsonMatcher
    end
  end

  describe '#Enum()' do
    it "[!fbfr0] creates Enum object which is a subclass of Set." do
      o = Enum("a", "b", "c")
      assert_eq o.class, Oktest::JsonMatcher::Enum
      assert    o.class < Set
      assert_eq (o === "a"), true
      assert_eq (o === "b"), true
      assert_eq (o === "c"), true
      assert_eq (o === "d"), false
    end
  end

  describe '#BOOL()' do
    it "[!vub5j] creates a set of true and false." do
      assert_eq BOOL().class, Oktest::JsonMatcher::Enum
      assert BOOL() === true
      assert BOOL() === false
      assert_eq (BOOL() === 1), false
      assert_eq (BOOL() === 0), false
    end
  end

  describe '#OR()' do
    it "[!9e8im] creates `OR` object." do
      o = OR(1, 2, 3)
      assert_eq o.class, Oktest::JsonMatcher::OR
    end
  end

  describe '#AND()' do
    it "[!38jln] creates `AND` object." do
      o = AND(4, 5, 6)
      assert_eq o.class, Oktest::JsonMatcher::AND
    end
  end

  describe '#Length()' do
    it "[!qqas3] creates Length object." do
      o = Length(3)
      assert_eq o.class, Oktest::JsonMatcher::Length
    end
  end

  describe '::ANY' do
    it "[!dlo1o] creates an AnythingOK object." do
      assert_eq ANY().class, Oktest::JsonMatcher::AnythingOK
    end
  end

end
