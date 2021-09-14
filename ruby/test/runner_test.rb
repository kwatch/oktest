# -*- coding: utf-8 -*-

###
### $Release: 1.1.1 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Runner_TC < TC

  class DummyReporter < Oktest::Reporter
    def enter_all(runner); end
    def exit_all(runner); end
    def enter_scope(scope)
      puts "file: #{scope.filename.inspect}"
    end
    def exit_scope(scope)
      puts "/file"
    end
    def enter_topic(topic, depth)
      puts "#{'  '*(depth-1)}topic: #{topic.target.inspect}"
    end
    def exit_topic(topic, depth)
      puts "#{'  '*(depth-1)}/topic"
    end
    def enter_spec(spec, depth)
      puts "#{'  '*(depth-1)}spec: #{spec.desc.inspect}"
    end
    def exit_spec(spec, depth, status, error, parent)
      if error
        if status == :FAIL
          puts "#{'  '*(depth-1)}/spec: status=#{status.inspect}, error=#<ASSERTION: #{error.message}>"
        else
          puts "#{'  '*(depth-1)}/spec: status=#{status.inspect}, error=#{error.inspect}"
        end
      else
        puts "#{'  '*(depth-1)}/spec: status=#{status.inspect}"
      end
    end
    #
    def counts; {}; end
  end

  class DummyReporter2 < DummyReporter
    def order_policy; :spec_first; end
  end

  describe "#start()" do
    build_topics = proc {
      Oktest.scope do
        topic "Parent" do
          topic "Child1" do
            spec "1+1 should be 2" do
              ok {1+1} == 2
            end
          end
        end
      end
    }
    it "[!xrisl] runs topics and specs." do
      sout, serr = capture do
        build_topics.call
        Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "Parent"
  topic: "Child1"
    spec: "1+1 should be 2"
    /spec: status=:PASS
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!dth2c] clears toplvel scope list." do
      assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, false
      sout, serr = capture do
        build_topics.call
        assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, true
        Oktest::Runner.new(DummyReporter.new).start()
      end
      assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, false
    end
  end

  describe "#visit_spec()" do
    it "[!yd24o] runs spec body, catching assertions or exceptions." do
      Oktest.scope do
        topic "Parent" do
          topic "Child" do
            spec("spec#1") { ok {1+1} == 2 }              # pass
            spec("spec#2") { ok {1+1} == 1 }              # fail
            spec("spec#3") { "".null? }                   # error
            spec("spec#4") { skip_when(true, "REASON") }  # skip
            spec("spec#5") { TODO(); ok {1+1} == 1 }      # todo (fail, so passed)
            spec("spec#6") { TODO(); ok {1+1} == 2 }      # todo (pass, but failed)
            spec("spec#7")                                # todo
          end
        end
      end
      sout, serr = capture do
        runner = Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "Parent"
  topic: "Child"
    spec: "spec#1"
    /spec: status=:PASS
    spec: "spec#2"
    /spec: status=:FAIL, error=#<ASSERTION: $<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 1>
    spec: "spec#3"
    /spec: status=:ERROR, error=#<NoMethodError: undefined method `null?' for "":String>
    spec: "spec#4"
    /spec: status=:SKIP, error=#<Oktest::SkipException: REASON>
    spec: "spec#5"
    /spec: status=:TODO, error=#<Oktest::TodoException: not implemented yet>
    spec: "spec#6"
    /spec: status=:FAIL, error=#<ASSERTION: spec should be failed (because not implemented yet), but passed unexpectedly.>
    spec: "spec#7"
    /spec: status=:TODO, error=#<Oktest::TodoException: not implemented yet>
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!u45di] runs spec block with context object which allows to call methods defined in topics." do
      Oktest.scope do
        def v1; "V1"; end
        topic "Parent" do
          def v2; "V2"; end
          topic "Child" do
            def v3; "V3"; end
            spec "spec#1" do
              p v1
              p v2
              p v3
            end
          end
        end
      end
      sout, serr = capture do
        runner = Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "Parent"
  topic: "Child"
    spec: "spec#1"
"V1"
"V2"
"V3"
    /spec: status=:PASS
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!yagka] calls 'before' and 'after' blocks with context object as self." do
      sout, serr = capture do
        Oktest.scope do
          before     { @x ||= 1; puts "      [all] before: @x=#{@x}" }
          after      {           puts "      [all] after:  @x=#{@x}" }
          topic "Parent" do
            before   { @x ||= 2; puts "      [Parent] before: @x=#{@x}" }
            after    {           puts "      [Parent] after:  @x=#{@x}" }
            topic "Child1" do
              before { @x ||= 3; puts "      [Child1] before: @x=#{@x}" }
              after  {           puts "      [Child1] after:  @x=#{@x}" }
              spec("spec#1") {   puts "      @x=#{@x}" }
              spec("spec#2") {   puts "      @x=#{@x}" }
            end
            topic "Child2" do
              spec("spec#3") {   puts "      @x=#{@x}" }
              spec("spec#4") {   puts "      @x=#{@x}" }
            end
          end
        end
        runner = Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "Parent"
  topic: "Child1"
    spec: "spec#1"
      [all] before: @x=1
      [Parent] before: @x=1
      [Child1] before: @x=1
      @x=1
      [Child1] after:  @x=1
      [Parent] after:  @x=1
      [all] after:  @x=1
    /spec: status=:PASS
    spec: "spec#2"
      [all] before: @x=1
      [Parent] before: @x=1
      [Child1] before: @x=1
      @x=1
      [Child1] after:  @x=1
      [Parent] after:  @x=1
      [all] after:  @x=1
    /spec: status=:PASS
  /topic
  topic: "Child2"
    spec: "spec#3"
      [all] before: @x=1
      [Parent] before: @x=1
      @x=1
      [Parent] after:  @x=1
      [all] after:  @x=1
    /spec: status=:PASS
    spec: "spec#4"
      [all] before: @x=1
      [Parent] before: @x=1
      @x=1
      [Parent] after:  @x=1
      [all] after:  @x=1
    /spec: status=:PASS
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!76g7q] calls 'after' blocks even when exception raised." do
      sout, serr = capture do
        Oktest.scope do
          after { puts "[all] after" }
          topic "Parent" do
            after    { puts "[Parent] after" }
            topic "Child" do
              after  { puts "[Child] after" }
              spec("spec#1") { ok {1+1} == 1 }
            end
          end
        end
        runner = Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "Parent"
  topic: "Child"
    spec: "spec#1"
[Child] after
[Parent] after
[all] after
    /spec: status=:FAIL, error=#<ASSERTION: $<actual> == $<expected>: failed.
    $<actual>:   2
    $<expected>: 1>
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!dihkr] calls 'at_end' blocks, even when exception raised." do
      sout, serr = capture do
        Oktest.scope do
          topic "topic#A" do
            spec("spec#1") { at_end { puts "  - at_end A1" } }
            spec("spec#2") { at_end { puts "  - at_end A2" }; "".null? }   # raises NoMethodError
          end
        end
        runner = Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "topic#A"
  spec: "spec#1"
  - at_end A1
  /spec: status=:PASS
  spec: "spec#2"
  - at_end A2
  /spec: status=:ERROR, error=#<NoMethodError: undefined method `null?' for "":String>
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    describe "[!68cnr] if TODO() called in spec..." do
      it "[!6ol3p] changes PASS status to FAIL because test passed unexpectedly." do
        Oktest.scope do
          topic "topic#A" do
            spec("spec#1") { TODO(); ok {1+1} == 2 }  # passed unexpectedly
          end
        end
        sout, serr = capture { Oktest::Runner.new(DummyReporter.new).start() }
        expected = <<'END'
file: "test/runner_test.rb"
topic: "topic#A"
  spec: "spec#1"
  /spec: status=:FAIL, error=#<ASSERTION: spec should be failed (because not implemented yet), but passed unexpectedly.>
/topic
/file
END
        assert_eq sout, expected
      end
      it "[!6syw4] changes FAIL status to TODO because test failed expectedly." do
        Oktest.scope do
          topic "topic#A" do
            spec("spec#1") { TODO(); ok {1+1} == 1 }  # failed expectedly
          end
        end
        sout, serr = capture { Oktest::Runner.new(DummyReporter.new).start() }
        expected = <<'END'
file: "test/runner_test.rb"
topic: "topic#A"
  spec: "spec#1"
  /spec: status=:TODO, error=#<Oktest::TodoException: not implemented yet>
/topic
/file
END
        assert_eq sout, expected
      end
      it "[!4aecm] changes also ERROR status to TODO because test failed expectedly." do
        Oktest.scope do
          topic "topic#B" do
            spec("spec#2") { TODO(); ok {foobar} == nil }  # will be error expectedly
          end
        end
        sout, serr = capture { Oktest::Runner.new(DummyReporter.new).start() }
        expected = <<'END'
file: "test/runner_test.rb"
topic: "topic#B"
  spec: "spec#2"
  /spec: status=:TODO, error=#<Oktest::TodoException: NameError raised because not implemented yet>
/topic
/file
END
        assert_eq sout, expected
      end
    end
  end

  describe "#visit_topic()" do
    it "[!i3yfv] calls 'before_all' and 'after_all' blocks." do
      sout, serr = capture do
        Oktest.scope do
          before_all { puts "[all] before_all" }
          after_all  { puts "[all] after_all" }
          topic "Parent" do
            before_all { puts "  [Parent] before_all" }
            after_all  { puts "  [Parent] after_all" }
            topic "Child1" do
              before_all { puts "    [Child1] before_all" }
              after_all  { puts "    [Child1] after_all" }
              spec("1+1 should be 2") { ok {1+1} == 2 }
              spec("1-1 should be 0") { ok {1-1} == 0 }
            end
            topic "Child2" do
              spec("1*1 should be 1") { ok {1*1} == 1 }
              spec("1/1 should be 1") { ok {1/1} == 1 }
            end
          end
        end
        Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
[all] before_all
topic: "Parent"
  [Parent] before_all
  topic: "Child1"
    [Child1] before_all
    spec: "1+1 should be 2"
    /spec: status=:PASS
    spec: "1-1 should be 0"
    /spec: status=:PASS
    [Child1] after_all
  /topic
  topic: "Child2"
    spec: "1*1 should be 1"
    /spec: status=:PASS
    spec: "1/1 should be 1"
    /spec: status=:PASS
  /topic
  [Parent] after_all
/topic
[all] after_all
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!p3a5o] run specs and case_when in advance of specs and topics when SimpleReporter." do
      sout, serr = capture do
        Oktest.scope do
          topic "T1" do
            topic "T2" do
              spec("S1") { ok {1+1} == 2 }
            end
            spec("S2") { ok {1+1} == 2 }
            topic "T3" do
              spec("S3") { ok {1+1} == 2 }
            end
            case_when "T4" do
              spec("S4") { ok {1+1} == 2 }
            end
          end
        end
        Oktest::Runner.new(DummyReporter2.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "T1"
  spec: "S2"
  /spec: status=:PASS
  topic: "When T4"
    spec: "S4"
    /spec: status=:PASS
  /topic
  topic: "T2"
    spec: "S1"
    /spec: status=:PASS
  /topic
  topic: "T3"
    spec: "S3"
    /spec: status=:PASS
  /topic
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end

  describe "#visit_scope()" do
    it "[!5anr7] calls before_all and after_all blocks." do
      sout, serr = capture do
        Oktest.scope do
          before_all { puts "[all] before_all#1" }
          after_all  { puts "[all] after_all#1" }
        end
        Oktest.scope do
          before_all { puts "[all] before_all#2" }
          after_all  { puts "[all] after_all#2" }
        end
        Oktest::Runner.new(DummyReporter.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
[all] before_all#1
[all] after_all#1
/file
file: "test/runner_test.rb"
[all] before_all#2
[all] after_all#2
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!c5cw0] run specs and case_when in advance of specs and topics when SimpleReporter." do
      sout, serr = capture do
        Oktest.scope do
          topic "T1" do
            spec("S1") { ok {1+1} == 2 }
          end
          spec("S2") { ok {1+1} == 2 }
          case_when "T2" do
            spec("S3") { ok {1+1} == 2 }
          end
          topic "T3" do
            spec("S4") { ok {1+1} == 2 }
          end
          spec("S5") { ok {1+1} == 2 }
        end
        Oktest::Runner.new(DummyReporter2.new).start()
      end
      expected = <<'END'
file: "test/runner_test.rb"
spec: "S2"
/spec: status=:PASS
topic: "When T2"
  spec: "S3"
  /spec: status=:PASS
/topic
spec: "S5"
/spec: status=:PASS
topic: "T1"
  spec: "S1"
  /spec: status=:PASS
/topic
topic: "T3"
  spec: "S4"
  /spec: status=:PASS
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end


end


class RunnerFunctions_TC < TC

  def setup()
  end

  def teardown()
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  def plain2colored(str)
    str = str.gsub(/<R>(.*?)<\/R>/) { Oktest::Color.red($1) }
    str = str.gsub(/<G>(.*?)<\/G>/) { Oktest::Color.green($1) }
    str = str.gsub(/<B>(.*?)<\/B>/) { Oktest::Color.blue($1) }
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

  def prepare()
    Oktest.scope do
      topic 'Example' do
        spec '1+1 should be 2' do
          ok {1+1} == 2
        end
        spec '1-1 should be 0' do
          ok {1-1} == 0
        end
      end
    end
  end

  VERBOSE_OUTPUT = <<'END'
## test/runner_test.rb
* <b>Example</b>
  - [<B>pass</B>] 1+1 should be 2
  - [<B>pass</B>] 1-1 should be 0
## total:2 (<B>pass:2</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
  COMPACT_OUTPUT = <<'END'
test/runner_test.rb: <B>.</B><B>.</B>
## total:2 (<B>pass:2</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
  PLAIN_OUTPUT = <<'END'
<B>.</B><B>.</B>
## total:2 (<B>pass:2</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END


  describe 'Oktest.run()' do
    it "[!mn451] run test cases." do
      expected = VERBOSE_OUTPUT
      prepare()
      sout, serr = capture { Oktest.run() }
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end
    it "[!6xn3t] creates reporter object according to 'style:' keyword arg." do
      expected = VERBOSE_OUTPUT
      prepare()
      sout, serr = capture { Oktest.run(:style=>"verbose") }
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
      #
      expected = COMPACT_OUTPUT
      prepare()
      sout, serr = capture { Oktest.run(:style=>"compact") }
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
      #
      expected = PLAIN_OUTPUT
      prepare()
      sout, serr = capture { Oktest.run(:style=>"plain") }
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end
    it "[!p52se] returns total number of failures and errors." do
      prepare()
      ret = nil
      _ = capture { ret = Oktest.run() }
      assert_eq ret, 0          # no failures, no errors
      #
      Oktest.scope do
        topic 'Example' do
          spec('pass') { ok {1+1} == 2 }
          spec('fail') { ok {1*1} == 2 }
          spec('error') { ok {1/0} == 0 }
          spec('skip') { skip_when true, "reason" }
          spec('todo')
        end
      end
      _ = capture { ret = Oktest.run() }
      assert_eq ret, 2          # 1 failure, 1 error
    end
  end

end
