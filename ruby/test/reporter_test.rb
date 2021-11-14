# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


module ReporterTestHelper

  def plain2colored(str)
    str = str.gsub(/<R>(.*?)<\/R>/) { Oktest::Color.red($1) }
    str = str.gsub(/<G>(.*?)<\/G>/) { Oktest::Color.green($1) }
    str = str.gsub(/<B>(.*?)<\/B>/) { Oktest::Color.blue($1) }
    str = str.gsub(/<C>(.*?)<\/C>/) { Oktest::Color.cyan($1) }
    str = str.gsub(/<M>(.*?)<\/M>/) { Oktest::Color.magenta($1) }
    str = str.gsub(/<Y>(.*?)<\/Y>/) { Oktest::Color.yellow($1) }
    str = str.gsub(/<b>(.*?)<\/b>/) { Oktest::Color.bold($1) }
    return str
  end

  def edit_actual(output)
    bkup = output.dup
    output = output.gsub(/^.*\r/, '')
    output = output.gsub(/^    .*(_test\.tmp:\d+)/, '    \1')
    output = output.gsub(/^    .*test.reporter_test\.rb:.*\n(    .*\n)*/, "%%%\n")
    output = output.sub(/ in \d+\.\d\d\ds/, ' in 0.000s')
    return output
  end

  def edit_expected(expected)
    expected = expected.gsub(/^    (.*:\d+)(:in `block .*)/, '    \1') if RUBY_VERSION < "1.9"
    expected = plain2colored(expected)
    return expected
  end

end


class BaseReporter_TC < TC
  include ReporterTestHelper

  def new_topic_and_spec()
    sc = Oktest::ScopeNode.new(nil, "foo.rb")
    t1 = Oktest::TopicNode.new(sc, 'Example')
    t2 = Oktest::TopicNode.new(t1, Array)
    t3 = Oktest::TopicNode.new(t2, 'When some condition')
    spec = Oktest::SpecLeaf.new(t3, "1+1 shoould be 2.") { nil }
    return t3, spec
  end

  describe '#enter_all()' do
    it "[!pq3ia] initalizes counter by zero." do
      r = Oktest::BaseReporter.new
      c = r.instance_eval { @counts }
      assert_eq c, {}
      #
      r.enter_all(nil)
      c = r.instance_eval { @counts }
      assert_eq c, {:PASS=>0, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
    end
  end

  describe '#exit_all()' do
    it "[!wjp7u] prints footer with elapsed time." do
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      r.instance_eval { @start_at = Time.now - 7.0 }
      sout, serr = capture do
        r.exit_all(nil)
      end
      assert_eq sout, "## total:0 (pass:0, fail:0, error:0, skip:0, todo:0) in 7.00s\n"
      assert_eq serr, ""
    end
  end

  describe '#exit_spec()' do
    it "[!r6yge] increments counter according to status." do
      begin; 1/0
      rescue => exc
      end
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      topic1, spec1 = new_topic_and_spec()
      #
      r.exit_spec(spec1, 1, :PASS, nil, topic1)
      assert_eq r.counts, {:PASS=>1, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :FAIL, exc, topic1)
      assert_eq r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>0, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :ERROR, exc, topic1)
      assert_eq r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :SKIP, nil, topic1)
      assert_eq r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>1, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :TODO, nil, topic1)
      assert_eq r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>1, :TODO=>1}
    end
    it "[!nupb4] keeps exception info when status is FAIL or ERROR." do
      begin; 1/0
      rescue => exc
      end
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      topic1, spec1 = new_topic_and_spec()
      counts = r.instance_variable_get('@counts')
      #
      r.exit_spec(spec1, 1, :PASS, nil, topic1)
      r.exit_spec(spec1, 1, :FAIL, exc, topic1)
      r.exit_spec(spec1, 1, :ERROR, exc, topic1)
      r.exit_spec(spec1, 1, :SKIP, nil, topic1)
      r.exit_spec(spec1, 1, :TODO, nil, topic1)
      #
      exceptions = r.instance_variable_get('@exceptions')
      assert_eq exceptions.length, 2
      assert_eq exceptions[0][1], :FAIL
      assert_eq exceptions[1][1], :ERROR
    end
  end

  describe '#reset_counts()' do
    it "[!oc29s] clears counters to zero." do
      r = Oktest::BaseReporter.new
      r.instance_eval do
        @counts = {:PASS=>5, :FAIL=>4, :ERROR=>3, :SKIP=>2, :TODO=>1}
      end
      r.__send__(:reset_counts)
      assert_eq r.instance_variable_get('@counts'), {:PASS=>0, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
    end
  end

  describe '#print_exc_message()' do
    def error_msg()
      return ("something failed\n"\
              "  expect: foo\n"\
              "  actual: bar\n")
    end
    it "[!hr7jn] prints detail of assertion failed." do
      errmsg = error_msg()
      exc = Oktest::AssertionFailed.new(errmsg)
      r = Oktest::BaseReporter.new
      sout, serr = capture do
        r.__send__(:print_exc_message, exc, :FAIL)
      end
      assert_eq sout, errmsg
      assert_eq serr, ""
    end
    it "[!pd41p] prints detail of exception." do
      errmsg = error_msg()
      exc = Oktest::AssertionFailed.new(errmsg)
      r = Oktest::BaseReporter.new
      sout, serr = capture do
        r.__send__(:print_exc_message, exc, :ERROR)
      end
      assert_eq sout, "Oktest::AssertionFailed: "+errmsg
      assert_eq serr, ""
    end
  end

  describe '#print_exc_backtrace()' do
    it "[!ocxy6] prints backtrace info and lines in file." do
      begin
        if true
          if true
            lineno = __LINE__ + 1
            raise Oktest::AssertionFailed, "something failed."
          end
        end
      rescue Oktest::AssertionFailed => exc
      end
      #
      expected = <<END
    test/reporter_test.rb:#{lineno}:in `block (2 levels) in <class:BaseReporter_TC>'
        raise Oktest::AssertionFailed, "something failed."
END
      #
      r = Oktest::BaseReporter.new
      sout, serr = capture do
        r.__send__(:print_exc_backtrace, exc, :FAIL)
      end
      assert sout.start_with?(expected), "traceback not matched"
      assert_eq serr, ""
    end
    it "[!jbped] skips backtrace of oktest.rb when assertion failure." do
      begin
        eval "raise Oktest::AssertionFailed, 'dummie'", binding(), "lib/oktest.rb", 100
      rescue Oktest::AssertionFailed => exc
      end
      #
      status = :FAIL
      sout, serr = capture do
        Oktest::BaseReporter.new.__send__(:print_exc_backtrace, exc, status)
      end
      assert sout !~ /lib\/oktest\.rb:/, "should skip but not"
      assert_eq serr, ""
    end
    it "[!cfkzg] don't skip first backtrace entry when error." do
      begin
        eval "raise Oktest::AssertionFailed, 'dummie'", binding(), "lib/oktest.rb", 100
      rescue Oktest::AssertionFailed => exc
      end
      #
      status = :ERROR
      sout, serr = capture do
        Oktest::BaseReporter.new.__send__(:print_exc_backtrace, exc, status)
      end
      assert sout =~ /lib\/oktest\.rb:100/, "should not skip but does"
      assert_eq serr, ""
    end
  end

  describe '#print_exc()' do
    it "[!5ara3] prints exception info of assertion failure." do
      begin
        if true
          lineno = __LINE__ + 1
          raise Oktest::AssertionFailed, 'dummie:43201'
        end
      rescue Oktest::AssertionFailed => exc
      end
      #
      expected = <<END
[<R>Fail</R>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>
    #{__FILE__}:#{lineno}:in `block (2 levels) in <class:BaseReporter_TC>'
        raise Oktest::AssertionFailed, 'dummie:43201'
END
      #
      topic1, spec1 = new_topic_and_spec()
      status = :FAIL
      sout, serr = capture do
        Oktest::BaseReporter.new.__send__(:print_exc, spec1, status, exc, topic1)
      end
      assert sout.start_with?(plain2colored(expected)), "not matched"
      assert_eq serr, ""
    end
    it "[!pcpy4] prints exception info of error." do
      begin
        if true
          lineno = __LINE__ + 1
          1/0
        end
      rescue ZeroDivisionError => exc
      end
      #
      expected = <<END
[<R>ERROR</R>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>
    #{__FILE__}:#{lineno}:in `/'
        1/0
END
      #
      topic1, spec1 = new_topic_and_spec()
      status = :ERROR
      sout, serr = capture do
        Oktest::BaseReporter.new.__send__(:print_exc, spec1, status, exc, topic1)
      end
      assert sout.start_with?(plain2colored(expected)), "not matched"
      assert_eq serr, ""
    end
  end

  describe '#print_exception()' do
    def new_reporter_with_exceptions(exc)
      topic1, spec1 = new_topic_and_spec()
      r = Oktest::BaseReporter.new
      r.instance_eval do
        if exc
          @exceptions = [
            [spec1, :FAIL, exc, topic1],
            [spec1, :ERROR, exc, topic1],
          ]
        end
      end
      return r
    end
    it "[!fbr16] prints assertion failures and excerptions with separator." do
      begin
        raise Oktest::AssertionFailed, 'dummie'
      rescue Oktest::AssertionFailed => exc
      end
      r = new_reporter_with_exceptions(exc)
      sep = "----------------------------------------------------------------------\n"
      expected1 = "[<R>Fail</R>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>\n"
      expected2 = "[<R>ERROR</R>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>\n"
      #
      sout, serr = capture { r.__send__(:print_exceptions) }
      assert sout.start_with?(sep + plain2colored(expected1)), "not matched"
      assert sout.include?(sep + plain2colored(expected2)), "not matched"
      assert sout.end_with?(sep), "not matched"
      assert_eq serr, ""
    end
    it "[!2s9r2] prints nothing when no fails nor errors." do
      r = new_reporter_with_exceptions(nil)
      sout, serr = capture { r.__send__(:print_exceptions) }
      assert_eq sout, ""
      assert_eq serr, ""
    end
    it "[!ueeih] clears exceptions." do
      begin 1/0
      rescue => exc
      end
      r = new_reporter_with_exceptions(exc)
      assert ! r.instance_variable_get('@exceptions').empty?
      sout, serr = capture { r.__send__(:print_exceptions) }
      assert   r.instance_variable_get('@exceptions').empty?
    end
  end

  describe '#footer()' do
    def new_footer(elapsed=0.5)
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      r.instance_eval do
        @counts = {:PASS=>5, :FAIL=>4, :ERROR=>3, :SKIP=>2, :TODO=>1}
      end
      return r.__send__(:footer, elapsed)
    end

    it "[!iy4uo] calculates total count of specs." do
      ft = new_footer()
      assert ft =~ /total:15 /, "failed to calculate total counts."
    end

    it "[!2nnma] includes count of each status." do
      ft = new_footer()
      assert ft =~ /pass:5\b/  , "failed to count passed status."
      assert ft =~ /fail:4\b/  , "failed to count failed status."
      assert ft =~ /error:3\b/ , "failed to count error status."
      assert ft =~ /skip:2\b/  , "failed to count skipped status."
      assert ft =~ /todo:1\b/   , "failed to count todo status."
    end

    it "[!fp57l] includes elapsed time." do
      ft = new_footer()
      assert ft =~ / in 0.500s$/, "failed to embed elapsed time."
    end

    it "[!r5y02] elapsed time format is adjusted along to time length." do
      assert new_footer(     0.5) =~ / in 0.500s$/       , "failed to embed elapsed time."
      assert new_footer(     6.5) =~ / in 6.50s$/        , "failed to embed elapsed time."
      assert new_footer(    17.5) =~ / in 17.5s$/        , "failed to embed elapsed time."
      assert new_footer(    61.5) =~ / in 1:01.5s$/      , "failed to embed elapsed time."
      assert new_footer(   610.5) =~ / in 10:10.5s$/     , "failed to embed elapsed time."
      assert new_footer(  3600.5) =~ / in 1:00:00.5s$/   , "failed to embed elapsed time."
      assert new_footer( 36000.5) =~ / in 10:00:00.5s$/  , "failed to embed elapsed time."
      assert new_footer(360000.5) =~ / in 100:00:00.5s$/ , "failed to embed elapsed time."
    end

    it "[!gx0n2] builds footer line." do
      expected = "## total:15 (<C>pass:5</C>, <R>fail:4</R>, <R>error:3</R>, <Y>skip:2</Y>, <Y>todo:1</Y>) in 0.500s"
      assert new_footer(), plain2colored(expected)
    end
  end

  describe '#spec_path()' do
    it "[!dv6fu] returns path string from top topic to current spec." do
      sc = Oktest::ScopeNode.new(nil, "foo.rb")
      t1 = Oktest::TopicNode.new(sc, 'Example')
      t2 = Oktest::TopicNode.new(t1, Array)
      t3 = Oktest::TopicNode.new(t2, 'When some condition')
      s1 = Oktest::SpecLeaf.new(t3, "1+1 shoould be 2.") { nil }
      path = Oktest::BaseReporter.new.__send__(:spec_path, s1, t3)
      assert_eq path, "Example > Array > When some condition > 1+1 shoould be 2."
    end
  end

end


class Reporter_TC < TC
  include ReporterTestHelper

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

    topic "Child3" do
      spec "skip example" do
        skip_when true, "a certain condition"
      end
      spec "todo example"
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

    spec "last spec" do
      ok {1+1} == 2
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
$<actual> == $<expected>: failed.
    $<actual>:   1
    $<expected>: 2
----------------------------------------------------------------------
[<R>ERROR</R>] <b>Parent > Child2 > 1/1 should be 1</b>
    _test.tmp:21:in `/'
        ok {1/0} == 1
%%%
ZeroDivisionError: divided by 0
----------------------------------------------------------------------
END

  FOOTER = <<'END'
## total:9 (<C>pass:5</C>, <R>fail:1</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END

  VERBOSE_PART = <<'END'
## _test.tmp
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
  * <b>Child2</b>
    - [<R>Fail</R>] 1*1 should be 1
    - [<R>ERROR</R>] 1/1 should be 1
END
  VERBOSE_PART2 = <<'END'
  * <b>Child3</b>
    - [<Y>Skip</Y>] skip example <Y>(reason: a certain condition)</Y>
    - [<Y>TODO</Y>] todo example
  - <b>When x is negative</b>
    - [<C>pass</C>] x*x is positive.
  - <b>Else</b>
    - [<C>pass</C>] x*x is also positive.
  - [<C>pass</C>] last spec
END
  VERBOSE_OUTPUT = VERBOSE_PART + ERROR_PART + VERBOSE_PART2 + FOOTER

  SIMPLE_PART = <<'END'
## _test.tmp
* <b>Parent</b>: <C>.</C><C>.</C><C>.</C>
  * <b>Child1</b>: <C>.</C><C>.</C>
  * <b>Child2</b>: <R>f</R><R>E</R>
END
  SIMPLE_PART2 = <<'END'
  * <b>Child3</b>: <Y>s</Y><Y>t</Y>
END
  SIMPLE_OUTPUT = SIMPLE_PART + ERROR_PART + SIMPLE_PART2 + FOOTER

  COMPACT_PART = <<'END'
_test.tmp: <C>.</C><C>.</C><R>f</R><R>E</R><Y>s</Y><Y>t</Y><C>.</C><C>.</C><C>.</C>
END
  COMPACT_OUTPUT = COMPACT_PART + ERROR_PART + FOOTER

  PLAIN_PART = <<'END'
<C>.</C><C>.</C><R>f</R><R>E</R><Y>s</Y><Y>t</Y><C>.</C><C>.</C><C>.</C>
END
  PLAIN_OUTPUT = PLAIN_PART + ERROR_PART + FOOTER

  QUIET_PART = <<'END'
<R>f</R><R>E</R><Y>s</Y><Y>t</Y>
END
  QUIET_OUTPUT = QUIET_PART + ERROR_PART + FOOTER

  def default_test
  end

  def setup
    @filename = "_test.tmp"
    File.write(@filename, INPUT)
    @_color_enabled = Oktest::Config.color_enabled
    Oktest::Config.color_enabled = true
  end

  def teardown
    Oktest::Config.color_enabled = @_color_enabled
    File.unlink(@filename) if @filename && File.exist?(@filename)
  end

  def run(*opts)
    return capture { Oktest::MainApp.main(opts) }
  end

end


class VerboseReporter_TC < Reporter_TC

  it "[!6o9nw] reports topic name and spec desc." do
    sout, serr = run("-sv", @filename)
    assert_eq edit_actual(sout), edit_expected(VERBOSE_OUTPUT)
    assert_eq serr, ""
  end

end


class SimpleReporter_TC < Reporter_TC

  it "[!jxa1b] reports topics and progress." do
    sout, serr = run("-ss", @filename)
    assert_eq edit_actual(sout), edit_expected(SIMPLE_OUTPUT)
    assert_eq serr, ""
  end

end


class CompactReporter_TC < Reporter_TC

  it "[!xfd5o] reports filename." do
    sout, serr = run("-sc", @filename)
    assert_eq edit_actual(sout), edit_expected(COMPACT_OUTPUT)
    assert_eq serr, ""
  end

end


class PlainReporter_TC < Reporter_TC

  it "[!w842j] reports progress." do
    sout, serr = run("-sp", @filename)
    assert_eq edit_actual(sout), edit_expected(PLAIN_OUTPUT)
    assert_eq serr, ""
  end

end


class QuietReporter_TC < Reporter_TC

  it "[!0z4im] reports all statuses except PASS status." do
    sout, serr = run("-sq", @filename)
    assert_eq edit_actual(sout), edit_expected(QUIET_OUTPUT)
    assert_eq serr, ""
  end

end
