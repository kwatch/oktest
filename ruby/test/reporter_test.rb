# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


module ReporterTestHelper

  INPUT_7 = <<'END'
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

  def default_test
  end

  def test_subject(desc, &b)
    @filename = "_test.tmp"
    File.write(@filename, INPUT_7)
    color_enabled = Oktest::Config.color_enabled
    Oktest::Config.color_enabled = true
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::Config.color_enabled = color_enabled
    File.unlink(@filename) if @filename && File.exist?(@filename)
  end

  def run(*opts)
    return capture_output! { Oktest::MainApp.main(opts) }
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


Object.new.instance_eval do   # Oktest::BaseReporter
  extend NanoTest
  extend ReporterTestHelper

  def self.new_topic_and_spec()
    sc = Oktest::ScopeNode.new(nil, "foo.rb")
    t1 = Oktest::TopicNode.new(sc, 'Example')
    t2 = Oktest::TopicNode.new(t1, Array)
    t3 = Oktest::TopicNode.new(t2, 'When some condition')
    spec = Oktest::SpecLeaf.new(t3, "1+1 shoould be 2.") { nil }
    return t3, spec
  end

  test_target 'Oktest::BaseReporter#enter_all()' do
    test_subject "[!pq3ia] initalizes counter by zero." do
      r = Oktest::BaseReporter.new
      c = r.instance_eval { @counts }
      test_eq? c, {}
      #
      r.enter_all(nil)
      c = r.instance_eval { @counts }
      test_eq? c, {:PASS=>0, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
    end
  end

  test_target 'Oktest::BaseReporter#exit_all()' do
    test_subject "[!wjp7u] prints footer with elapsed time." do
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      r.instance_eval { @start_at = Time.now - 7.0 }
      sout, serr = capture_output! do
        r.exit_all(nil)
      end
      test_eq? sout, "## total:0 (pass:0, fail:0, error:0, skip:0, todo:0) in 7.00s\n"
      test_eq? serr, ""
    end
  end

  test_target 'Oktest::BaseReporter#exit_spec()' do
    test_subject "[!r6yge] increments counter according to status." do
      begin; 1/0
      rescue => exc
      end
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      topic1, spec1 = new_topic_and_spec()
      #
      r.exit_spec(spec1, 1, :PASS, nil, topic1)
      test_eq? r.counts, {:PASS=>1, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :FAIL, exc, topic1)
      test_eq? r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>0, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :ERROR, exc, topic1)
      test_eq? r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>0, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :SKIP, nil, topic1)
      test_eq? r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>1, :TODO=>0}
      #
      r.exit_spec(spec1, 1, :TODO, nil, topic1)
      test_eq? r.counts, {:PASS=>1, :FAIL=>1, :ERROR=>1, :SKIP=>1, :TODO=>1}
    end
    test_subject "[!nupb4] keeps exception info when status is FAIL or ERROR." do
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
      test_eq? exceptions.length, 2
      test_eq? exceptions[0][1], :FAIL
      test_eq? exceptions[1][1], :ERROR
    end
  end

  test_target 'Oktest::BaseReporter#reset_counts()' do
    test_subject "[!oc29s] clears counters to zero." do
      r = Oktest::BaseReporter.new
      r.instance_eval do
        @counts = {:PASS=>5, :FAIL=>4, :ERROR=>3, :SKIP=>2, :TODO=>1}
      end
      r.__send__(:reset_counts)
      test_eq? r.instance_variable_get('@counts'), {:PASS=>0, :FAIL=>0, :ERROR=>0, :SKIP=>0, :TODO=>0}
    end
  end

  test_target 'Oktest::BaseReporter#print_exc_message()' do
    def self.error_msg()
      return ("something failed\n"\
              "  expect: foo\n"\
              "  actual: bar\n")
    end
    test_subject "[!hr7jn] prints detail of assertion failed." do
      errmsg = error_msg()
      exc = Oktest::AssertionFailed.new(errmsg)
      r = Oktest::BaseReporter.new
      sout, serr = capture_output! do
        r.__send__(:print_exc_message, exc, :FAIL)
      end
      test_eq? sout, plain2colored(<<END)
<R>something failed</R>
  expect: foo
  actual: bar
END
      test_eq? serr, ""
    end
    test_subject "[!pd41p] prints detail of exception." do
      errmsg = error_msg()
      exc = Oktest::AssertionFailed.new(errmsg)
      r = Oktest::BaseReporter.new
      sout, serr = capture_output! do
        r.__send__(:print_exc_message, exc, :ERROR)
      end
      test_eq? sout, plain2colored(<<END)
<R>Oktest::AssertionFailed: something failed</R>
  expect: foo
  actual: bar
END
      test_eq? serr, ""
    end
  end

  test_target 'Oktest::BaseReporter#print_exc_backtrace()' do
    test_subject "[!ocxy6] prints backtrace info and lines in file." do
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
    test/reporter_test.rb:#{lineno}:in `block (3 levels) in <main>'
        raise Oktest::AssertionFailed, "something failed."
END
      #
      r = Oktest::BaseReporter.new
      sout, serr = capture_output! do
        r.__send__(:print_exc_backtrace, exc, :FAIL)
      end
      sout = sout.sub(/ in <.*?>/, " in <main>")
      test_ok? sout.start_with?(expected), msg: "traceback not matched"
      test_eq? serr, ""
    end
    test_subject "[!jbped] skips backtrace of oktest.rb when assertion failure." do
      exc = test_exception? Oktest::AssertionFailed do
        eval "raise Oktest::AssertionFailed, 'dummie'", binding(), "lib/oktest.rb", 100
      end
      #
      status = :FAIL
      sout, serr = capture_output! do
        Oktest::BaseReporter.new.__send__(:print_exc_backtrace, exc, status)
      end
      test_ok? sout !~ /lib\/oktest\.rb:/, msg: "should skip but not"
      test_eq? serr, ""
    end
    test_subject "[!cfkzg] don't skip first backtrace entry when error." do
      exc = test_exception? Oktest::AssertionFailed do
        eval "raise Oktest::AssertionFailed, 'dummie'", binding(), "lib/oktest.rb", 100
      end
      #
      status = :ERROR
      sout, serr = capture_output! do
        Oktest::BaseReporter.new.__send__(:print_exc_backtrace, exc, status)
      end
      test_ok? sout =~ /lib\/oktest\.rb:100/, msg: "should not skip but does"
      test_eq? serr, ""
    end
  end

  test_target 'Oktest::BaseReporter#print_exc()' do
    test_subject "[!5ara3] prints exception info of assertion failure." do
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
    #{__FILE__}:#{lineno}:in `block (3 levels) in <main>'
        raise Oktest::AssertionFailed, 'dummie:43201'
END
      #
      topic1, spec1 = new_topic_and_spec()
      status = :FAIL
      sout, serr = capture_output! do
        Oktest::BaseReporter.new.__send__(:print_exc, spec1, status, exc, topic1)
      end
      sout = sout.gsub(/ in <.*?>/, " in <main>")
      test_ok? sout.start_with?(plain2colored(expected)), msg: "not matched"
      test_eq? serr, ""
    end
    test_subject "[!pcpy4] prints exception info of error." do
      begin
        if true
          lineno = __LINE__ + 1
          1/0
        end
      rescue ZeroDivisionError => exc
      end
      #
      expected = <<END
[<E>ERROR</E>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>
    #{__FILE__}:#{lineno}:in `/'
        1/0
END
      #
      topic1, spec1 = new_topic_and_spec()
      status = :ERROR
      sout, serr = capture_output! do
        Oktest::BaseReporter.new.__send__(:print_exc, spec1, status, exc, topic1)
      end
      test_ok? sout.start_with?(plain2colored(expected)), msg: "not matched"
      test_eq? serr, ""
    end
  end

  test_target 'Oktest::BaseReporter#print_exception()' do
    def self.new_reporter_with_exceptions(exc)
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
    test_subject "[!fbr16] prints assertion failures and excerptions with separator." do
      begin
        raise Oktest::AssertionFailed, 'dummie'
      rescue Oktest::AssertionFailed => exc
      end
      r = new_reporter_with_exceptions(exc)
      sep = "----------------------------------------------------------------------\n"
      expected1 = "[<R>Fail</R>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>\n"
      expected2 = "[<E>ERROR</E>] <b>Example > Array > When some condition > 1+1 shoould be 2.</b>\n"
      #
      sout, serr = capture_output! { r.__send__(:print_exceptions) }
      test_ok? sout.start_with?(sep + plain2colored(expected1)), msg: "not matched"
      test_ok? sout.include?(sep + plain2colored(expected2)), msg: "not matched"
      test_ok? sout.end_with?(sep), msg: "not matched"
      test_eq? serr, ""
    end
    test_subject "[!2s9r2] prints nothing when no fails nor errors." do
      r = new_reporter_with_exceptions(nil)
      sout, serr = capture_output! { r.__send__(:print_exceptions) }
      test_eq? sout, ""
      test_eq? serr, ""
    end
    test_subject "[!ueeih] clears exceptions." do
      begin 1/0
      rescue => exc
      end
      r = new_reporter_with_exceptions(exc)
      test_ok? ! r.instance_variable_get('@exceptions').empty?
      sout, serr = capture_output! { r.__send__(:print_exceptions) }
      test_ok?   r.instance_variable_get('@exceptions').empty?
    end
  end

  test_target 'Oktest::BaseReporter#footer()' do
    def self.new_footer(elapsed=0.5)
      r = Oktest::BaseReporter.new
      r.enter_all(nil)
      r.instance_eval do
        @counts = {:PASS=>5, :FAIL=>4, :ERROR=>3, :SKIP=>2, :TODO=>1}
      end
      return r.__send__(:footer, elapsed)
    end

    test_subject "[!iy4uo] calculates total count of specs." do
      ft = new_footer()
      test_ok? ft =~ /total:15 /, msg: "failed to calculate total counts."
    end

    test_subject "[!2nnma] includes count of each status." do
      ft = new_footer()
      test_ok? ft =~ /pass:5\b/  , msg: "failed to count passed status."
      test_ok? ft =~ /fail:4\b/  , msg: "failed to count failed status."
      test_ok? ft =~ /error:3\b/ , msg: "failed to count error status."
      test_ok? ft =~ /skip:2\b/  , msg: "failed to count skipped status."
      test_ok? ft =~ /todo:1\b/  , msg: "failed to count todo status."
    end

    test_subject "[!fp57l] includes elapsed time." do
      ft = new_footer()
      test_ok? ft =~ / in 0.500s$/, msg: "failed to embed elapsed time."
    end

    test_subject "[!r5y02] elapsed time format is adjusted along to time length." do
      test_ok? new_footer(     0.5) =~ / in 0.500s$/       , msg: "failed to embed elapsed time."
      test_ok? new_footer(     6.5) =~ / in 6.50s$/        , msg: "failed to embed elapsed time."
      test_ok? new_footer(    17.5) =~ / in 17.5s$/        , msg: "failed to embed elapsed time."
      test_ok? new_footer(    61.5) =~ / in 1:01.5s$/      , msg: "failed to embed elapsed time."
      test_ok? new_footer(   610.5) =~ / in 10:10.5s$/     , msg: "failed to embed elapsed time."
      test_ok? new_footer(  3600.5) =~ / in 1:00:00.5s$/   , msg: "failed to embed elapsed time."
      test_ok? new_footer( 36000.5) =~ / in 10:00:00.5s$/  , msg: "failed to embed elapsed time."
      test_ok? new_footer(360000.5) =~ / in 100:00:00.5s$/ , msg: "failed to embed elapsed time."
    end

    test_subject "[!gx0n2] builds footer line." do
      expected = "## total:15 (<C>pass:5</C>, <R>fail:4</R>, <E>error:3</E>, <Y>skip:2</Y>, <Y>todo:1</Y>) in 0.500s"
      test_eq? new_footer(), plain2colored(expected)
    end
  end

  test_target 'Oktest::BaseReporter#spec_path()' do
    test_subject "[!dv6fu] returns path string from top topic to current spec." do
      sc = Oktest::ScopeNode.new(nil, "foo.rb")
      t1 = Oktest::TopicNode.new(sc, 'Example')
      t2 = Oktest::TopicNode.new(t1, Array)
      t3 = Oktest::TopicNode.new(t2, 'When some condition')
      s1 = Oktest::SpecLeaf.new(t3, "1+1 shoould be 2.") { nil }
      path = Oktest::BaseReporter.new.__send__(:spec_path, s1, t3)
      test_eq? path, "Example > Array > When some condition > 1+1 shoould be 2."
    end
  end

end


module ReporterOutput

  ERROR_PART = <<'END'
----------------------------------------------------------------------
[<R>Fail</R>] <b>Parent > Child2 > 1*1 should be 1</b>
    _test.tmp:18:in `block (4 levels) in <top (required)>'
        ok {1*1} == 2
%%%
<R>$<actual> == $<expected>: failed.</R>
    $<actual>:   1
    $<expected>: 2
----------------------------------------------------------------------
[<E>ERROR</E>] <b>Parent > Child2 > 1/1 should be 1</b>
    _test.tmp:21:in `/'
        ok {1/0} == 1
%%%
<R>ZeroDivisionError: divided by 0</R>
----------------------------------------------------------------------
END

  FOOTER = <<'END'
## total:9 (<C>pass:5</C>, <R>fail:1</R>, <E>error:1</E>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END

  VERBOSE_PART = <<'END'
## _test.tmp
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
  * <b>Child2</b>
    - [<R>Fail</R>] 1*1 should be 1
    - [<E>ERROR</E>] 1/1 should be 1
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
  * <b>Child2</b>: <R>f</R><E>E</E>
END
  SIMPLE_PART2 = <<'END'
  * <b>Child3</b>: <Y>s</Y><Y>t</Y>
END
  SIMPLE_OUTPUT = SIMPLE_PART + ERROR_PART + SIMPLE_PART2 + FOOTER

  COMPACT_PART = <<'END'
_test.tmp: <C>.</C><C>.</C><R>f</R><E>E</E><Y>s</Y><Y>t</Y><C>.</C><C>.</C><C>.</C>
END
  COMPACT_OUTPUT = COMPACT_PART + ERROR_PART + FOOTER

  PLAIN_PART = <<'END'
<C>.</C><C>.</C><R>f</R><E>E</E><Y>s</Y><Y>t</Y><C>.</C><C>.</C><C>.</C>
END
  PLAIN_OUTPUT = PLAIN_PART + ERROR_PART + FOOTER

  QUIET_PART = <<'END'
<R>f</R><E>E</E><Y>s</Y><Y>t</Y>
END
  QUIET_OUTPUT = QUIET_PART + ERROR_PART + FOOTER

end

include ReporterOutput


Object.new.instance_eval do   # Oktest::VerboseReporter
  extend NanoTest
  extend ReporterTestHelper

  test_subject "[!6o9nw] reports topic name and spec desc." do
    sout, serr = run("-sv", @filename)
    test_eq? edit_actual(sout), edit_expected(VERBOSE_OUTPUT)
    test_eq? serr, ""
  end

  test_subject "[!ibdu7] reports errors even when no topics." do
    input = <<'END'
require 'oktest'
Oktest.scope do
  spec "example" do
    ok {1-1} == 2
  end
end
END
    File.write(@filename, input)
    #
    expected = <<'END'
## _test.tmp
- [<R>Fail</R>] example
----------------------------------------------------------------------
[<R>Fail</R>] <b>example</b>
    _test.tmp:4:in `block (2 levels) in <top (required)>'
        ok {1-1} == 2
%%%
<R>$<actual> == $<expected>: failed.</R>
    $<actual>:   0
    $<expected>: 2
----------------------------------------------------------------------
## total:1 (pass:0, <R>fail:1</R>, error:0, skip:0, todo:0) in 0.000s
END
    #
    sout, serr = run("-sv", @filename)
    test_eq? edit_actual(sout), edit_expected(expected)
    test_eq? serr, ""
  end

end


Object.new.instance_eval do   # Oktest::SimpleReporter
  extend NanoTest
  extend ReporterTestHelper
  extend ReporterOutput

  test_subject "[!jxa1b] reports topics and progress." do
    sout, serr = run("-ss", @filename)
    test_eq? edit_actual(sout), edit_expected(SIMPLE_OUTPUT)
    test_eq? serr, ""
  end

end


Object.new.instance_eval do   # Oktest::CompactReporter
  extend NanoTest
  extend ReporterTestHelper
  extend ReporterOutput

  test_subject "[!xfd5o] reports filename." do
    sout, serr = run("-sc", @filename)
    test_eq? edit_actual(sout), edit_expected(COMPACT_OUTPUT)
    test_eq? serr, ""
  end

end


Object.new.instance_eval do   # Oktest::PlainReporter
  extend NanoTest
  extend ReporterTestHelper
  extend ReporterOutput

  test_subject "[!w842j] reports progress." do
    sout, serr = run("-sp", @filename)
    test_eq? edit_actual(sout), edit_expected(PLAIN_OUTPUT)
    test_eq? serr, ""
  end

end


Object.new.instance_eval do   # Oktest::QuietReporter
  extend NanoTest
  extend ReporterTestHelper
  extend ReporterOutput

  test_subject "[!0z4im] reports all statuses except PASS status." do
    sout, serr = run("-sq", @filename)
    test_eq? edit_actual(sout), edit_expected(QUIET_OUTPUT)
    test_eq? serr, ""
  end

end


Object.new.instance_eval do   # Oktest
  extend NanoTest
  extend ReporterTestHelper
  extend ReporterOutput

  test_target 'Oktest.DEFAULT_REPORTING_STYLE=()' do
    test_subject "[!lbufd] raises error if unknown style specified." do
      exc = test_exception? ArgumentError do
        Oktest.DEFAULT_REPORTING_STYLE = "foo"
      end
      test_eq? exc.message, "foo: Unknown reporting style."
    end
    test_subject "[!dsbmo] changes value of default reporting style." do
      test_eq? Oktest::DEFAULT_REPORTING_STYLE, "verbose"
      begin
        Oktest.DEFAULT_REPORTING_STYLE = "plain"
        test_eq? Oktest::DEFAULT_REPORTING_STYLE, "plain"
      ensure
        Oktest.DEFAULT_REPORTING_STYLE = "verbose"
      end
    end
  end

end
