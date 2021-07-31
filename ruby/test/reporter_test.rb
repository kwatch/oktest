###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Reporter_TC < TC

  def plain2colored(str)
    str = str.gsub(/<R>(.*?)<\/R>/) { Oktest::Color.red($1) }
    str = str.gsub(/<G>(.*?)<\/G>/) { Oktest::Color.green($1) }
    str = str.gsub(/<B>(.*?)<\/B>/) { Oktest::Color.blue($1) }
    str = str.gsub(/<Y>(.*?)<\/Y>/) { Oktest::Color.yellow($1) }
    str = str.gsub(/<b>(.*?)<\/b>/) { Oktest::Color.bold($1) }
    return str
  end

  INPUT = <<'END'
require 'oktest'

Oktest.scope do

  topic "Parent" do

    topic "Child1" do
      spec "1+1 should be 2" do
        ok {1+1} == 2
      end
      spec "1-1 should be 0" do
        ok {1-1} == 0
      end
    end

    topic "Child2" do
      spec "1*1 should be 1" do
        ok {1*1} == 2
      end
      spec "1/1 should be 1" do
        ok {1/0} == 1
      end
    end

    case_when "x is negative" do
      spec "x*x is positive." do
        x = -2
        ok {x*x} > 0
      end
    end

    case_else do
      spec "x*x is also positive." do
        x = 2
        ok {x*x} > 0
      end
    end

  end

end

END

  ERROR_PART = <<'END'
----------------------------------------------------------------------
[<R>Fail</R>] <b>Parent > Child2 > 1*1 should be 1</b>
    _test.tmp:18:in `block (4 levels) in <top (required)>'
        ok {1*1} == 2
%%%
$actual == $expected: failed.
    $actual:   1
    $expected: 2
----------------------------------------------------------------------
[<R>ERROR</R>] <b>Parent > Child2 > 1/1 should be 1</b>
    _test.tmp:21:in `/'
        ok {1/0} == 1
%%%
ZeroDivisionError: divided by 0
----------------------------------------------------------------------
END

  FOOTER = <<'END'
## total:6, <G>pass:4</G>, <R>fail:1</R>, <R>error:1</R>, skip:0, todo:0  (in 0.000s)
END

  VERBOSE_PART = <<'END'
* <b>Parent</b>
  * <b>Child1</b>
    - [<G>pass</G>] 1+1 should be 2
    - [<G>pass</G>] 1-1 should be 0
  * <b>Child2</b>
    - [<R>Fail</R>] 1*1 should be 1
    - [<R>ERROR</R>] 1/1 should be 1
END
  VERBOSE_PART2 = <<'END'
  - <b>When x is negative</b>
    - [<G>pass</G>] x*x is positive.
  - <b>Else</b>
    - [<G>pass</G>] x*x is also positive.
END
  VERBOSE_OUTPUT = VERBOSE_PART + ERROR_PART + VERBOSE_PART2 + FOOTER

  SIMPLE_PART = <<'END'
_test.tmp: <G>.</G><G>.</G><R>f</R><R>E</R><G>.</G><G>.</G>
END
  SIMPLE_OUTPUT = SIMPLE_PART + ERROR_PART + FOOTER

  PLAIN_PART = <<'END'
<G>.</G><G>.</G><R>f</R><R>E</R><G>.</G><G>.</G>
END
  PLAIN_OUTPUT = PLAIN_PART + ERROR_PART + FOOTER

  def edit_actual(output)
    bkup = output.dup
    output = output.gsub(/^.*\r/, '')
    output = output.gsub(/^    .*(_test\.tmp:\d+)/, '    \1')
    output = output.gsub(/^    .*test.reporter_test\.rb:.*\n(    .*\n)*/, "%%%\n")
    output = output.sub(/\(in \d+\.\d\d\ds\)/, '(in 0.000s)')
    return output
  end

  def edit_expected(expected)
    expected = expected.gsub(/^    (.*:\d+)(:in `block .*)/, '    \1') if RUBY_VERSION < "1.9"
    expected = plain2colored(expected)
    return expected
  end

  def default_test
  end

  def setup
    @filename = "_test.tmp"
    File.write(@filename, INPUT)
  end

  def teardown
    File.unlink(@filename) if @filename && File.exist?(@filename)
  end

end


class VerboseReporter_TC < Reporter_TC

  it "reports topic name and spec desc." do
    sout, serr = capture do
      load(@filename)
      Oktest::main()
    end
    assert_eq edit_actual(sout), edit_expected(VERBOSE_OUTPUT)
    assert_eq serr, ""
  end

end


class SimpleReporter_TC < Reporter_TC

  it "reports filename." do
    sout, serr = capture do
      load(@filename)
      Oktest::main(["-ss"])
    end
    assert_eq edit_actual(sout), edit_expected(SIMPLE_OUTPUT)
    assert_eq serr, ""
  end

end


class PlainReporter_TC < Reporter_TC

  it "reports resuls only." do
    sout, serr = capture do
      load(@filename)
      Oktest::main(["-sp"])
    end
    assert_eq edit_actual(sout), edit_expected(PLAIN_OUTPUT)
    assert_eq serr, ""
  end

end