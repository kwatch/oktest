###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Runner_TC < TC

  class DummyReporter < Oktest::Reporter
    def enter_all(runner); end
    def exit_all(runner); end
    def enter_file(filename)
      puts "file: #{filename.inspect}"
    end
    def exit_file(filename)
      puts "/file"
    end
    def enter_topic(topic, depth)
      puts "#{'  '*depth}topic: #{topic.name.inspect}"
    end
    def exit_topic(topic, depth)
      puts "#{'  '*depth}/topic"
    end
    def enter_spec(spec, depth)
      puts "#{'  '*depth}spec: #{spec.desc.inspect}"
    end
    def exit_spec(spec, depth, status, error, parent)
      if error
        if status == :FAIL
          puts "#{'  '*depth}/spec: status=#{status.inspect}, error=#<ASSERTION: #{error.message}>"
        else
          puts "#{'  '*depth}/spec: status=#{status.inspect}, error=#{error.inspect}"
        end
      else
        puts "#{'  '*depth}/spec: status=#{status.inspect}"
      end
    end
    #
    def counts; {}; end
  end

  describe "#run_all()" do
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
    it "runs topics and specs." do
      sout, serr = capture do
        build_topics.call
        Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "clears filescopes list." do
      assert Oktest::FILESCOPES.empty?, "Oktest::FILESCOPES should NOT be empty #1"
      sout, serr = capture do
        build_topics.call
        assert !Oktest::FILESCOPES.empty?, "Oktest::FILESCOPES should be empty"
        Oktest::Runner.new(DummyReporter.new).run_all()
      end
      assert Oktest::FILESCOPES.empty?, "Oktest::FILESCOPES should NOT be empty #2"
    end
  end

  describe "#run_spec()" do
    it "runs spec body, catching assertions or exceptions." do
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
        runner = Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "runs spec block with context object which allows to call methods defined in topics." do
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
        runner = Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "calls 'before' and 'after' blocks with context object as self." do
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
        runner = Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "calls 'after' blocks even when exception raised." do
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
        runner = Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "calls 'at_end' blocks, even when exception raised." do
      sout, serr = capture do
        Oktest.scope do
          topic "topic#A" do
            spec("spec#1") { at_end { puts "  - at_end A1" } }
            spec("spec#2") { at_end { puts "  - at_end A2" }; "".null? }   # raises NoMethodError
          end
        end
        runner = Oktest::Runner.new(DummyReporter.new).run_all()
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
    it "skips spec if $OKTEST_SPEC is set and it is not equal to spec text." do
      sout, serr = capture do
        Oktest.scope do
          topic "topic#A" do
            spec("spec#1") { ok {1+1} == 2 }
            spec("spec#2") { ok {1-1} == 0 }
          end
        end
        ENV['OKTEST_SPEC'] = "spec#2"
        begin
          runner = Oktest::Runner.new(DummyReporter.new).run_all()
        ensure
          ENV['OKTEST_SPEC'] = nil
        end
      end
      expected = <<'END'
file: "test/runner_test.rb"
topic: "topic#A"
  spec: "spec#2"
  /spec: status=:PASS
/topic
/file
END
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end

  describe "#run_topic()" do
    it "calls 'before_all' and 'after_all' blocks." do
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
        Oktest::Runner.new(DummyReporter.new).run_all()
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
  end

  describe "#run_filescope()" do
    it "calls before_all and after_all blocks." do
      sout, serr = capture do
        Oktest.scope do
          before_all { puts "[all] before_all#1" }
          after_all  { puts "[all] after_all#1" }
        end
        Oktest.scope do
          before_all { puts "[all] before_all#2" }
          after_all  { puts "[all] after_all#2" }
        end
        Oktest::Runner.new(DummyReporter.new).run_all()
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
  end


end
