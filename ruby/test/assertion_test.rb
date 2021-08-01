###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class TestUnitTestCase_TC < TC
  include Test::Unit::Assertions

  describe "#ok()" do
    it "availables in Test::Unit::TestCase." do
      assert_nothing_raised do
        ok {1+1} == 2
      end
    end
  end

end


class AssertionObject_TC < TC
  include Test::Unit::Assertions

  def should_be_failed(errmsg, &block)
    ex = assert_raise Oktest::FAIL_EXCEPTION do
      block.call
    end
    case errmsg
    when Regexp;  assert_match errmsg, ex.message
    else;         assert_equal errmsg, ex.message
    end
  end

  def should_return_self
    obj = yield
    assert obj.class == Oktest::AssertionObject
  end

  describe "#==" do
    it "returns self when passed." do
      should_return_self { ok {1+1} == 2 }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {1+1} == 3 }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {1+1}.NOT == 3 }
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      should_be_failed(errmsg) { ok {1+1}.NOT == 2 }
    end
    it "shows context diff when both actual and expected are text." do
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
      errmsg.gsub!(/1,4/, '1,3') #if RUBY_VERSION < "1.9.2"
      should_be_failed(errmsg) { ok {actual} == expected }
    end
  end

  describe "#!=" do
    it "returns self when passed." do
      should_return_self { ok {1+1} != 3 }
    end
    it "raises assertion error when failed." do
      #errmsg = "<2> expected to be != to\n<2>."
      errmsg = "$<actual> != $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 2"
      should_be_failed(errmsg) { ok {1+1} != 2 }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {1+1}.NOT != 2 }
      #errmsg = "<3> expected but was\n<2>."
      errmsg = "$<actual> == $<expected>: failed.\n"\
               "    $<actual>:   2\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {1+1}.NOT != 3 }
    end
  end #if RUBY_VERSION >= "1.9"

  describe "#===" do
    it "returns self when passed." do
      should_return_self { ok {String} === 'str' }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual> === $<expected>: failed.\n"\
               "    $<actual>:   Integer\n"\
               "    $<expected>: \"str\""
      should_be_failed(errmsg) { ok {Integer} === 'str' }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {Integer}.NOT === 'str' }
      errmsg = "!($<actual> === $<expected>): failed.\n"\
               "    $<actual>:   String\n"\
               "    $<expected>: \"str\""
      should_be_failed(errmsg) { ok {String}.NOT === 'str' }
    end
  end

  describe ">" do
    it "returns self when passed." do
      should_return_self { ok {2} > 1 }
    end
    it "raises assertion error when failed." do
      #errmsg = "Expected 2 to be > 2."
      errmsg = "2 > 2: failed."
      should_be_failed(errmsg) { ok {2} > 2 }
      errmsg = "1 > 2: failed."
      should_be_failed(errmsg) { ok {1} > 2 }
      #
      errmsg = "\"aaa\" > \"bbb\": failed."
      should_be_failed(errmsg) { ok {'aaa'} > 'bbb' }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {2}.NOT > 2 }
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      should_be_failed(errmsg) { ok {2}.NOT > 1 }
    end
  end

  describe ">=" do
    it "returns self when passed." do
      should_return_self { ok {2} >= 2 }
      should_return_self { ok {2} >= 1 }
    end
    it "raises assertion error when failed." do
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      should_be_failed(errmsg) { ok {1} >= 2 }
      #
      errmsg = "\"aaa\" >= \"bbb\": failed."
      should_be_failed(errmsg) { ok {'aaa'} >= 'bbb' }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {1}.NOT >= 2 }
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      should_be_failed(errmsg) { ok {2}.NOT >= 2 }
    end
  end

  describe "<" do
    it "returns self when passed." do
      should_return_self { ok {1} < 2 }
    end
    it "raises assertion error when failed." do
      #errmsg = "Expected 2 to be < 2."
      errmsg = "2 < 2: failed."
      should_be_failed(errmsg) { ok {2} < 2 }
      errmsg = "2 < 1: failed."
      should_be_failed(errmsg) { ok {2} < 1 }
      #
      errmsg = "\"bbb\" < \"aaa\": failed."
      should_be_failed(errmsg) { ok {'bbb'} < 'aaa' }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {2}.NOT < 2 }
      #errmsg = "Expected 1 to be >= 2."
      errmsg = "1 >= 2: failed."
      should_be_failed(errmsg) { ok {1}.NOT < 2 }
    end
  end

  describe "<=" do
    it "returns self when passed." do
      should_return_self { ok {1} <= 2 }
      should_return_self { ok {1} <= 1 }
    end
    it "raises assertion error when failed." do
      #errmsg = "Expected 2 to be <= 1."
      errmsg = "2 <= 1: failed."
      should_be_failed(errmsg) { ok {2} <= 1 }
      #
      errmsg = "\"bbb\" <= \"aaa\": failed."
      should_be_failed(errmsg) { ok {'bbb'} <= 'aaa' }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {2}.NOT <= 1 }
      #errmsg = "Expected 1 to be > 2."
      errmsg = "1 > 2: failed."
      should_be_failed(errmsg) { ok {1}.NOT <= 2 }
    end
  end

  describe "=~" do
    it "returns self when passed." do
      should_return_self { ok {'SOS'} =~ /^[A-Z]+$/ }
    end
    it "raises assertion error when failed." do
      #errmsg = 'Expected /^\\d+$/ to match "SOS".'
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /^\\d+$/\n"\
               "    $<actual>:   <<'END'\n"\
               "SOS\n"\
               "END\n"
      should_be_failed(errmsg) { ok {"SOS\n"} =~ /^\d+$/ }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {'SOS'}.NOT =~ /^\d+$/ }
      #errmsg = "</\\w+/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /\\w+/\n"\
               "    $<actual>:   \"SOS\"\n"
      should_be_failed(errmsg) { ok {'SOS'}.NOT =~ /\w+/ }
    end if false
  end

  describe "!~" do
    it "returns self when passed." do
      should_return_self { ok {'SOS'} !~ /^\d+$/ }
    end
    it "raises assertion error when failed." do
      #errmsg = "</^\\w+$/> expected to not match\n<\"SOS\">."
      errmsg = "$<actual> !~ $<expected>: failed.\n"\
               "    $<expected>: /^\\w+$/\n"\
               "    $<actual>:   \"SOS\"\n"
      should_be_failed(errmsg) { ok {'SOS'} !~ /^\w+$/ }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {'SOS'}.NOT !~ /^\w+$/ }
      #errmsg = "Expected /\\d+/ to match \"SOS\"."
      errmsg = "$<actual> =~ $<expected>: failed.\n"\
               "    $<expected>: /\\d+/\n"\
               "    $<actual>:   <<'END'\nSOS\nEND\n"
      should_be_failed(errmsg) { ok {"SOS\n"}.NOT !~ /\d+/ }
    end
  end #if RUBY_VERSION >= "1.9"

  describe "#in_delta?" do
    it "returns self when passed." do
      should_return_self { ok {3.14159}.in_delta?(3.141, 0.001) }
    end
    it "raises assertion error when failed." do
      errmsg = "($<actual> - $<expected>).abs < #{0.1}: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      should_be_failed(errmsg) { ok {1.375}.in_delta?(1.5, 0.1) }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {1.375}.NOT.in_delta?(1.5, 0.1) }
      errmsg = "($<actual> - $<expected>).abs < #{0.2} == false: failed.\n"\
               "    $<actual>:   1.375\n"\
               "    $<expected>: 1.5\n"\
               "    ($<actual> - $<expected>).abs: #{0.125}"
      should_be_failed(errmsg) { ok {1.375}.NOT.in_delta?(1.5, 0.2) }
    end
  end

  describe "#same?" do
    it "returns self when passed." do
      should_return_self { ok {:SOS}.same?(:SOS) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual>.equal?($<expected>): failed.\n"\
               "    $<actual>:   \"SOS\"\n"\
               "    $<expected>: \"SOS\"\n"
      should_be_failed(errmsg) { ok {'SOS'}.same?('SOS') }
    end
    it "is avaialbe with NOT." do
      should_return_self { ok {'SOS'}.NOT.same? 'SOS' }
      errmsg = "$<actual>.equal?($<expected>) == false: failed.\n"\
               "    $<actual>:   :SOS\n"\
               "    $<expected>: :SOS\n"
      should_be_failed(errmsg) { ok {:SOS}.NOT.same?(:SOS) }
    end
  end

  describe "#method_missing" do
    it "enables to handle boolean methods." do
      should_return_self { ok {""}.empty?  }
      should_return_self { ok {nil}.nil?  }
      should_return_self { ok {1}.is_a?(Integer)  }
    end
    it "fails when boolean method failed returned false." do
      errmsg = "$<actual>.empty?: failed.\n    $<actual>:   \"SOS\""
      should_be_failed(errmsg) { ok {"SOS"}.empty? }
      errmsg = "$<actual>.nil?: failed.\n    $<actual>:   \"\""
      should_be_failed(errmsg) { ok {""}.nil? }
      errmsg = "$<actual>.is_a?(Integer): failed.\n    $<actual>:   3.14"
      should_be_failed(errmsg) { ok {3.14}.is_a?(Integer) }
    end
    it "is available with NOT." do
      ok {"SOS"}.NOT.empty?
      ok {"SOS"}.NOT.nil?
      ok {"SOS"}.NOT.is_a?(Integer)
      errmsg = "$<actual>.empty? == false: failed.\n    $<actual>:   \"\""
      should_be_failed(errmsg) { ok {""}.NOT.empty? }
      errmsg = "$<actual>.nil? == false: failed.\n    $<actual>:   nil"
      should_be_failed(errmsg) { ok {nil}.NOT.nil? }
      errmsg = "$<actual>.is_a?(Integer) == false: failed.\n    $<actual>:   1"
      should_be_failed(errmsg) { ok {1}.NOT.is_a?(Integer) }
    end
    it "raises TypeError when boolean method returned non-boolean value." do
      errmsg = "$<actual>.empty?: failed.\n    $<actual>:   \"SOS\""
      ex = assert_raise(TypeError) {
        s = "SOS"
        def s.sos?; return 1; end
        ok {s}.sos?
      }
      errmsg = "ok(): String#sos?() expected to return true or false, but got 1."
      assert_equal errmsg, ex.message
    end
  end

  describe "#raise?" do
    it "returns self when passed." do
      pr = proc { "SOS".sos }
      should_return_self { ok {pr}.raise?(NoMethodError, "undefined method `sos' for \"SOS\":String")  }
    end
    it "raises assertion error when failed." do
      pr = proc { "SOS".sos }
      errmsg = "Expected ArgumentError to be raised but got NoMethodError."
      should_be_failed(errmsg) { ok {pr}.raise?(ArgumentError) }
      errmsg = "$error_message == \"FOOBAR\": failed.\n"\
               "    $error_message: \"undefined method `sos' for \\\"SOS\\\":String\""
      should_be_failed(errmsg) { ok {pr}.raise?(NoMethodError, "FOOBAR") }
    end
    it "accepts string or regexp as error message." do
      pr = proc { "SOS".sos }
      should_return_self { ok {pr}.raise?(NoMethodError, "undefined method `sos' for \"SOS\":String") }
      pr = proc { "SOS".sos }
      should_return_self { ok {pr}.raise?(NoMethodError, /^undefined method `sos' for "SOS":String$/) }
    end
    it "is available with NOT." do
      pr = proc { "SOS".length }
      should_return_self { ok {pr}.NOT.raise?  }
      pr = proc { "SOS".sos }
      should_return_self { ok {pr}.NOT.raise?(ArgumentError)  }
      errmsg = "NoMethodError should not be raised but got #<NoMethodError: undefined method `sos' for \"SOS\":String>."
      should_be_failed(errmsg) { ok {pr}.NOT.raise?(NoMethodError) }
    end
    it "sets exceptio object into '#exception' attribute." do
      pr = proc { "SOS".foobar }
      assert !pr.respond_to?(:exception)
      ok {pr}.raise?(NoMethodError)
      assert pr.respond_to?(:exception)
      assert pr.exception.is_a?(NoMethodError)
      assert_eq pr.exception.message, "undefined method `foobar' for \"SOS\":String"
    end
  end

  describe "#in?" do
    it "returns self when passed." do
      should_return_self { ok {3}.in?(1..5) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<expected>.include?($<actual>): failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..2"
      should_be_failed(errmsg) { ok {3}.in?(1..2) }
    end
    it "is available with NOT." do
      should_return_self { ok {3}.NOT.in?(1..2) }
      errmsg = "$<expected>.include?($<actual>) == false: failed.\n"\
               "    $<actual>:   3\n"\
               "    $<expected>: 1..5"
      should_be_failed(errmsg) { ok {3}.NOT.in?(1..5) }
    end
  end

  describe "#include?" do
    it "returns self when passed." do
      should_return_self { ok {1..5}.include?(3) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual>.include?($<expected>): failed.\n"\
               "    $<actual>:   1..2\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {1..2}.include?(3) }
    end
    it "is available with NOT." do
      should_return_self { ok {1..2}.NOT.include?(3) }
      errmsg = "$<actual>.include?($<expected>) == false: failed.\n"\
               "    $<actual>:   1..5\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {1..5}.NOT.include?(3) }
    end
  end

  describe "#attr()" do
    it "returns self when passed." do
      should_return_self { ok {"SOS"}.attr(:length, 3) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      should_be_failed(errmsg) { ok {"SOS"}.attr(:size, 2) }
    end
    it "is available with NOT." do
      should_return_self { ok {"SOS"}.NOT.attr(:length, 2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {"SOS"}.NOT.attr(:size, 3) }
    end
  end

  describe "#attrs()" do
    it "returns self when passed." do
      should_return_self { ok {"SOS"}.attrs(:length=>3, :size=>3) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual>.size == $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 2"
      should_be_failed(errmsg) { ok {"SOS"}.attrs(:size=>2) }
    end
    it "is available with NOT." do
      should_return_self { ok {"SOS"}.NOT.attrs(:length=>2) }
      errmsg = "$<actual>.size != $<expected>: failed.\n"\
               "    $<actual>.size: 3\n"\
               "    $<expected>: 3"
      should_be_failed(errmsg) { ok {"SOS"}.NOT.attrs(:size=>3) }
    end
  end

  describe "#keyval()" do
    it "returns self when passed." do
      d = {'a'=>1}
      should_return_self { ok {d}.keyval('a', 1) }
    end
    it "raises assertion error when failed." do
      d = {'a'=>1}
      errmsg = "$<actual>[\"a\"] == $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: \"1\""
      should_be_failed(errmsg) { ok {d}.keyval('a', '1') }
    end
    it "is available with NOT." do
      d = {'a'=>1}
      should_return_self { ok {d}.NOT.keyval('a', '1') }
      errmsg = "$<actual>[\"a\"] != $<expected>: failed.\n"\
               "    $<actual>[\"a\"]: 1\n"\
               "    $<expected>: 1"
      should_be_failed(errmsg) { ok {d}.NOT.keyval('a', 1) }
    end
  end

  describe "#length" do
    it "returns self when passed." do
      should_return_self { ok {"SOS"}.length(3) }
    end
    it "raises assertion error when failed." do
      errmsg = "$<actual>.length == 5: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      should_be_failed(errmsg) { ok {"SOS"}.length(5) }
    end
    it "is available with NOT." do
      should_return_self { ok {"SOS"}.NOT.length(5) }
      errmsg = "$<actual>.length != 3: failed.\n"\
               "    $<actual>.length: 3\n"\
               "    $<actual>:   \"SOS\""
      should_be_failed(errmsg) { ok {"SOS"}.NOT.length(3) }
    end
  end

  describe "#truthy?" do
    it "returns self when passed." do
      should_return_self { ok {""}.truthy? }
    end
    it "raises assertion error when failed." do
      errmsg = "!!$<actual> == true: failed.\n"\
               "    $<actual>:   nil"
      should_be_failed(errmsg) { ok {nil}.truthy? }
    end
    it "is available with NOT." do
      should_return_self { ok {nil}.NOT.truthy? }
      errmsg = "!!$<actual> != true: failed.\n"\
               "    $<actual>:   0"
      should_be_failed(errmsg) { ok {0}.NOT.truthy? }
    end
  end

  describe "#falsy?" do
    it "returns self when passed." do
      should_return_self { ok {nil}.falsy? }
    end
    it "raises assertion error when failed." do
      errmsg = "!!$<actual> == false: failed.\n"\
               "    $<actual>:   0"
      should_be_failed(errmsg) { ok {0}.falsy? }
    end
    it "is available with NOT." do
      should_return_self { ok {0}.NOT.falsy? }
      errmsg = "!!$<actual> != false: failed.\n"\
               "    $<actual>:   nil"
      should_be_failed(errmsg) { ok {nil}.NOT.falsy? }
    end
  end

  describe "#file_exist?" do
    it "returns self when passed." do
      should_return_self { ok {__FILE__}.file_exist? }
    end
    it "raises assertion error when failed." do
      errmsg = "File.file?($<actual>): failed.\n"\
               "    $<actual>:   \".\""
      should_be_failed(errmsg) { ok {'.'}.file_exist? }
    end
    it "is available with NOT." do
      should_return_self { ok {'.'}.NOT.file_exist? }
      errmsg = "File.file?($<actual>) == false: failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      should_be_failed(errmsg) { ok {__FILE__}.NOT.file_exist? }
    end
  end

  describe "#dir_exist?" do
    it "returns self when passed." do
      should_return_self { ok {'.'}.dir_exist? }
    end
    it "raises assertion error when failed." do
      errmsg = "File.directory?($<actual>): failed.\n"\
               "    $<actual>:   \"#{__FILE__}\""
      should_be_failed(errmsg) { ok {__FILE__}.dir_exist? }
    end
    it "is available with NOT." do
      should_return_self { ok {__FILE__}.NOT.dir_exist? }
      errmsg = "File.directory?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      should_be_failed(errmsg) { ok {'.'}.NOT.dir_exist? }
    end
  end

  describe "#symlink_exist?" do
    def with_symlink
      linkname = "_sym_#{rand().to_s[2...7]}"
      File.symlink(__FILE__, linkname)
      yield linkname
    ensure
      File.unlink(linkname)
    end
    it "returns self when passed." do
      with_symlink do |linkname|
        should_return_self { ok {linkname}.symlink_exist? }
      end
    end
    it "raises assertion error when failed." do
      with_symlink do |linkname|
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \"_not_exist\""
        should_be_failed(errmsg) { ok {'_not_exist'}.symlink_exist? }
        errmsg = "File.symlink?($<actual>): failed.\n"\
                 "    $<actual>:   \".\""
        should_be_failed(errmsg) { ok {'.'}.symlink_exist? }
      end
    end
    it "is available with NOT." do
      with_symlink do |linkname|
        should_return_self { ok {'_not_exist'}.NOT.symlink_exist? }
        should_return_self { ok {'.'}.NOT.symlink_exist? }
        errmsg = "File.symlink?($<actual>) == false: failed.\n"\
                 "    $<actual>:   \"#{linkname}\""
        should_be_failed(errmsg) { ok {linkname}.NOT.symlink_exist? }
      end
    end
  end

  describe "#not_exist?" do
    it "returns self when passed." do
      should_return_self { ok {'_not_exist'}.not_exist? }
    end
    it "raises assertion error when failed." do
      errmsg = "File.exist?($<actual>) == false: failed.\n"\
               "    $<actual>:   \".\""
      should_be_failed(errmsg) { ok {'.'}.not_exist? }
    end
    it "is available with NOT." do
      should_return_self { ok {'.'}.NOT.not_exist? }
      errmsg = "File.exist?($<actual>): failed.\n"\
               "    $<actual>:   \"_not_exist\""
      should_be_failed(errmsg) { ok {'_not_exist'}.NOT.not_exist? }
    end
  end

end
