# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest::MainApp
  extend NanoTest
  extend Oktest::SpecHelper

  def self.test_subject(desc, &b)
    @testfile = "_tmp_test.rb"
    File.write(@testfile, INPUT_5, encoding: 'utf-8')
    color_enabled = Oktest::Config.color_enabled
    Oktest::Config.color_enabled = true
    #
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::Config.color_enabled = color_enabled
    File.unlink(@testfile)
  end

  INPUT_5 = <<'END'
require 'oktest'

Oktest.scope do

  topic "Parent" do

    topic "Child1" do
      spec "1+1 should be 2" do
        ok {1+1} == 2
      end
      spec "1-1 should be 0", tag: 'new' do
        ok {1-1} == 0
      end
    end

    topic "Child2" do
      spec "1*1 should be 1", tag: 'fail' do
        ok {1*1} == 2
      end
      spec "1/1 should be 1", tag: 'err' do
        ok {1/0} == 1
      end
    end

    topic "Child3", tag: ['exp', 'new'] do
      spec "skip example" do
        skip_when true, "a certain condition"
      end
      spec "todo example"
    end

    case_when "x is negative", tag: 'exp' do
      spec "[!6hs1j] x*x is positive." do
        x = -2
        ok {x*x} > 0
      end
    end

    case_else do
      spec "[!pwiq7] x*x is also positive." do
        x = 2
        ok {x*x} > 0
      end
    end

  end

end

END

  def self.edit_actual(output)
    bkup = output.dup
    output = output.gsub(/^.*\r/, '')
    output = output.gsub(/^    .*(_test\.tmp:\d+)/, '    \1')
    output = output.gsub(/^    .*test.reporter_test\.rb:.*\n(    .*\n)*/, "%%%\n")
    output = output.sub(/ in \d+\.\d\d\ds/, ' in 0.000s')
    return output
  end

  def self.edit_expected(expected)
    expected = expected.gsub(/^    (.*:\d+)(:in `block .*)/, '    \1') if RUBY_VERSION < "1.9"
    expected = plain2colored(expected)
    return expected
  end


  test_target 'Oktest::MainApp.main()' do

    def self.main(argv)
      ret = nil
      sout, serr = capture do
        ret = Oktest::MainApp.main(argv)
      end
      return ret, sout, serr
    end

    test_subject "[!tb6sx] returns 0 when no errors raised." do
      ret, sout, serr = main(["-h"])
      test_eq? ret, 0
      test_eq? serr, ""
    end

    test_subject "[!d5mql] returns 1 when a certain error raised." do
      ret, sout, serr = main(["-U"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] -U: Unknown option.\n"
    end

    test_subject "[!jr49p] reports error when unknown option specified." do
      ret, sout, serr = main(["-X"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] -X: Unknown option.\n"
      #
      ret, sout, serr = main(["--foobar"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] --foobar: Unknown long option.\n"
    end

    test_subject "[!uqomj] reports error when required argument is missing." do
      ret, sout, serr = main(["-s"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] -s: Argument required.\n"
    end

    test_subject "[!8i755] reports error when argument is invalid." do
      ret, sout, serr = main(["-s", "foobar"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] -s foobar: Expected one of verbose/simple/compact/plain/quiet/v/s/c/p/q.\n"
      #
      ret, sout, serr = main(["-F", "aaa=*pat*"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] -F aaa=*pat*: Pattern unmatched.\n"
      #
      ret, sout, serr = main(["--color=abc"])
      test_eq? ret, 1
      test_eq? serr, "[ERROR] --color=abc: Boolean expected.\n"
    end

  end


  test_target 'Oktest::MainApp#run()' do

    def self.run(*args, tty: true)
      ret = nil
      sout, serr = capture("", tty: tty) do
        ret = Oktest::MainApp.new.run(*args)
      end
      return ret, sout, serr
    end

    test_subject "[!18qpe] runs test scripts." do
      expected = <<'END'
## total:8 (<C>pass:4</C>, <R>fail:1</R>, <E>error:1</E>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      ret, sout, serr = run(@testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).end_with?(edit_expected(expected)), msg: "invalid status line"
    end

    test_subject "[!k402d] raises error if file not found." do
      filename = "not-exist-file"
      exc = test_exception Benry::CmdOpt::OptionError do
        run(filename)
      end
      test_eq? exc.message, "#{filename}: not found."
    end

    test_subject "[!bim36] changes auto-running to off." do
      Oktest::Config.auto_run = true
      _ = run(@testfile)
      test_eq? Oktest::Config.auto_run, false
    end

    test_subject "[!hiu5b] finds test scripts in directory and runs them." do
      expected = <<'END'
## total:8 (<C>pass:4</C>, <R>fail:1</R>, <E>error:1</E>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      dir = "_tmpdir.d"
      dirs = [dir, "#{dir}/d1", "#{dir}/d1/d2"]
      dirs.each {|x| Dir.mkdir(x) unless File.directory?(x) }
      File.rename(@testfile, "#{dir}/d1/d2/#{@testfile}")
      begin
        ret, sout, serr = run(dir)
        test_eq? ret, 2
        test_ok? edit_actual(sout).end_with?(edit_expected(expected)), msg: "invalid status line"
      ensure
        File.rename("#{dir}/d1/d2/#{@testfile}", @testfile)
        dirs.reverse.each {|x| Dir.rmdir(x) }
      end
    end

    test_subject "[!v5xie] parses $OKTEST_RB environment variable." do
      ret, sout, serr = run(@testfile, tty: false)
      expected = plain2colored(<<'END')
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
END
      test_ok? sout.start_with?(expected), msg: "expected verbose-style, but not."
      #
      begin
        ENV['OKTEST_RB'] = "-ss"
        ret, sout, serr = run(@testfile, tty: false)
        expected = plain2colored(<<'END')
## _tmp_test.rb
* <b>Parent</b>: <C>.</C><C>.</C>
  * <b>Child1</b>: <C>.</C><C>.</C>
  * <b>Child2</b>: <R>f</R><E>E</E>
END
        test_ok? sout.start_with?(expected), msg: "expected simple-style, but not."
      ensure
        ENV.delete('OKTEST_RB')
      end
    end

    test_subject "[!tt2gj] parses command options even after filenames." do
      ret, sout, serr = run(@testfile, "--version")
      test_eq? ret, 0
      test_eq? sout, Oktest::VERSION+"\n"
      test_eq? serr, ""
    end

    #HELP_MESSAGE = Oktest::MainApp::HELP_MESSAGE % {command: File.basename($0)}
    HELP_MESSAGE = (<<"END") % {command: File.basename($0)}
\e[1mOktest\e[0m (#{Oktest::VERSION}) -- New style testing library

\e[36mUsage:\e[0m
  $ \e[1m%{command}\e[0m [<options>] [<file|directory>...]

\e[36mOptions:\e[0m
  -h, --help               : show help
      --version            : print version
  -s <reporting-style>     : verbose/simple/compact/plain/quiet, or v/s/c/p/q
  -F <key>=<pattern>       : filter topic or spec with pattern (see below)
      --color[=<on|off>]   : enable/disable output coloring forcedly
  -S, --skeleton           : print test code skeleton
  -G, --generate[=<style>] : generate test code skeleton from ruby file

\e[36mFilter Examples:\e[0m
  $ %{command} -F topic=Hello            # filter by topic
  $ %{command} -F spec='*hello*'         # filter by spec
  $ %{command} -F tag=name               # filter by tag name
  $ %{command} -F tag!=name              # negative filter by tag name
  $ %{command} -F tag='{name1,name2}'    # filter by multiple tag names

\e[36mDocument:\e[0m
  https://github.com/kwatch/oktest/blob/ruby/ruby/README.md
END

    test_subject "[!65vdx] prints help message if no arguments specified." do
      expected = HELP_MESSAGE
      ret, sout, serr = run()
      test_eq? ret, 0
      test_eq? sout, expected
      test_eq? serr, ""
    end

    test_subject "[!9973n] '-h' or '--help' option prints help message." do
      expected = HELP_MESSAGE
      #
      ret, sout, serr = run("-h")
      test_eq? ret, 0
      test_eq? sout, expected
      test_eq? serr, ""
      #
      ret, sout, serr = run("--help")
      test_eq? ret, 0
      test_eq? sout, expected
      test_eq? serr, ""
    end

    test_subject "[!v938d] help message will be colored only when stdout is a tty." do
      ret, sout, serr = run("-h", tty: true)
      test_ok? sout =~ /\e\[1mOktest\e\[0m/
      test_ok? sout =~ /\e\[36mOptions:\e\[0m/
      #
      ret, sout, serr = run("-h", tty: false)
      test_ok? sout !~ /\e\[1mOktest\e\[0m/
      test_ok? sout !~ /\e\[36mOptions:\e\[0m/
    end

    test_subject "[!qqizl] '--version' option prints version number." do
      expected = '$Release: 0.0.0 $'.split()[1] + "\n"
      #
      ret, sout, serr = run("--version")
      test_eq? ret, 0
      test_eq? sout, expected
      test_eq? serr, ""
    end

    test_subject "[!0qd92] '-s verbose' or '-sv' option prints test results in verbose mode." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
  * <b>Child2</b>
    - [<R>Fail</R>] 1*1 should be 1
    - [<E>ERROR</E>] 1/1 should be 1
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sv", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
      #
      ret, sout, serr = run("-s", "verbose", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
    end

    test_subject "[!zfdr5] '-s simple' or '-ss' option prints test results in simple mode." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>: <C>.</C><C>.</C>
  * <b>Child1</b>: <C>.</C><C>.</C>
  * <b>Child2</b>: <R>f</R><E>E</E>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-ss", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
      #
      ret, sout, serr = run("-s", "simple", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
    end

    test_subject "[!ef5v7] '-s compact' or '-sc' option prints test results in compact mode." do
      expected = <<END
#{@testfile}: <C>.</C><C>.</C><R>f</R><E>E</E><Y>s</Y><Y>t</Y><C>.</C><C>.</C>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sc", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
      #
      ret, sout, serr = run("-s", "compact", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
    end

    test_subject "[!244te] '-s plain' or '-sp' option prints test results in plain mode." do
      expected = <<END
<C>.</C><C>.</C><R>f</R><E>E</E><Y>s</Y><Y>t</Y><C>.</C><C>.</C>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sp", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
      #
      ret, sout, serr = run("-s", "plain", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
    end

    test_subject "[!ai61w] '-s quiet' or '-sq' option prints test results in quiet mode." do
      expected = <<END
<R>f</R><E>E</E><Y>s</Y><Y>t</Y>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sq", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
      #
      ret, sout, serr = run("-s", "quiet", @testfile)
      test_eq? ret, 2
      test_ok? edit_actual(sout).start_with?(edit_expected(expected)), msg: "invalid testcase output"
      test_eq? serr, ""
    end

    test_subject "[!yz7g5] '-F topic=...' option filters topics." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
## total:2 (<C>pass:2</C>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "topic=Child1", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!ww2mp] '-F spec=...' option filters specs." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1-1 should be 0
## total:1 (<C>pass:1</C>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "spec=*1-1*", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!8uvib] '-F tag=...' option filters by tag name." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1-1 should be 0
  * <b>Child3</b>
    - [<Y>Skip</Y>] skip example <Y>(reason: a certain condition)</Y>
    - [<Y>TODO</Y>] todo example
  - <b>When x is negative</b>
    - [<C>pass</C>] [!6hs1j] x*x is positive.
## total:4 (<C>pass:2</C>, fail:0, error:0, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag={new,exp}", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!m0iwm] '-F sid=...' option filters by spec id." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  - <b>When x is negative</b>
    - [<C>pass</C>] [!6hs1j] x*x is positive.
## total:1 (<C>pass:1</C>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "sid=6hs1j", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!noi8i] '-F' option supports negative filter." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<C>pass</C>] 1+1 should be 2
    - [<C>pass</C>] 1-1 should be 0
  - <b>Else</b>
    - [<C>pass</C>] [!pwiq7] x*x is also positive.
## total:3 (<C>pass:3</C>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag!={fail,err,exp}", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!71h2x] '-F ...' option will be error." do
      exc = test_exception Benry::CmdOpt::OptionError do
        run("-F", "*pat*", @testfile)
      end
      test_eq? exc.message, "-F *pat*: Pattern unmatched."
    end

    test_subject "[!j01y7] if filerting by '-F' matched nothing, then prints zero result." do
      expected = <<'END'
## total:0 (pass:0, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag=blablabla", @testfile)
      test_eq? ret, 0
      test_eq? edit_actual(sout), edit_expected(expected)
      test_eq? serr, ""
    end

    test_subject "[!6ro7j] '--color=on' option enables output coloring forcedly." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color=on", @testfile, tty: tty)
          test_ok? sout.include?(edit_expected("[<C>pass</C>]")), msg: "should contain blue string"
          test_ok? sout.include?(edit_expected("[<R>Fail</R>]")), msg: "should contain red string"
          test_ok? sout.include?(edit_expected("[<Y>Skip</Y>]")), msg: "should contain yellos string"
          test_eq? serr, ""
        end
      end
    end

    test_subject "[!dptgn] '--color' is same as '--color=on'." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color", @testfile, tty: tty)
          test_ok? sout.include?(edit_expected("[<C>pass</C>]")), msg: "should contain blue string"
          test_ok? sout.include?(edit_expected("[<R>Fail</R>]")), msg: "should contain red string"
          test_ok? sout.include?(edit_expected("[<Y>Skip</Y>]")), msg: "should contain yellos string"
          test_eq? serr, ""
        end
      end
    end

    test_subject "[!vmw0q] '--color=off' option disables output coloring forcedly." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color=off", @testfile, tty: tty)
          test_ok? !sout.include?(edit_expected("[<C>pass</C>]")), msg: "should not contain blue string"
          test_ok? !sout.include?(edit_expected("[<R>Fail</R>]")), msg: "should not contain red string"
          test_ok? !sout.include?(edit_expected("[<Y>Skip</Y>]")), msg: "should not contain yellos string"
          test_eq? serr, ""
        end
      end
    end

    test_subject "[!dk8eg] '-S' or '--skeleton' option prints test code skeleton." do
      ret, sout, serr = run("-S")
      test_eq? ret, 0
      test_eq? sout, Oktest::MainApp.new.__send__(:skeleton)
      test_eq? serr, ""
    end

    HELLO_CLASS_DEF = <<'END'
class Hello
  def hello(name=nil)
    #; default name is 'world'.
    if name.nil?
      name = "world"
    end
    #; returns greeting message.
    return "Hello, #{name}!"
  end
end
END

    test_subject "[!uxh5e] '-G' or '--generate' option prints test code." do
      input = HELLO_CLASS_DEF
      filename = "_tmpcode_4674.rb"
      File.write(filename, input)
      expected = <<END
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello()' do

      spec "default name is 'world'."

      spec "returns greeting message."

    end


  end  # Hello


end
END
      #
      begin
        ret, sout, serr = run("-G", filename)
        test_eq? ret, 0
        test_eq? sout, expected
        test_eq? serr, ""
        #
        ret, sout, serr = run("--generate", filename)
        test_eq? ret, 0
        test_eq? sout, expected
        test_eq? serr, ""
      ensure
        File.unlink(filename)
      end
    end

    test_subject "[!wmxu5] '--generate=unaryop' option prints test code with unary op." do
      input = HELLO_CLASS_DEF
      filename = "_tmpcode_6431.rb"
      File.write(filename, input)
      expected = <<END
# coding: utf-8

require 'oktest'

Oktest.scope do


+ topic(Hello) do


  + topic('#hello()') do

    - spec("default name is 'world'.")

    - spec("returns greeting message.")

    end


  end  # Hello


end
END
      #
      begin
        ret, sout, serr = run("-Gunaryop", filename)
        test_eq? ret, 0
        test_eq? sout, expected
        test_eq? serr, ""
        #
        ret, sout, serr = run("--generate=unaryop", filename)
        test_eq? ret, 0
        test_eq? sout, expected
        test_eq? serr, ""
      ensure
        File.unlink(filename)
      end
    end

    test_subject "[!qs8ab] '--faster' chanages 'Config.ok_location' to false." do
      test_eq? Oktest::Config.ok_location, true
      begin
        run("--faster", @testfile)
        test_eq? Oktest::Config.ok_location, false
      ensure
        Oktest::Config.ok_location = true
      end
    end

    test_subject "[!dsrae] reports if 'ok()' called but assertion not performed." do
      input = <<'END'
require 'oktest'
Oktest.scope do
  topic 'Example' do
    spec 'sample #1' do
      ok {1+1} == 2          # assertion performed
    end
    spec 'sample #2' do
      ok {1+1}               # ok() called but assertion not performed
    end
    spec 'sample #3' do
      ok {'abc'}.start_with?(str)   # assetion not performed unexpectedly
    end
  end
end
END
      File.write(@testfile, input)
      expected = <<END
** warning: ok() is called but not tested yet (at #{@testfile}:8:in `block (3 levels) in <top (required)>').
** warning: ok() is called but not tested yet (at #{@testfile}:11:in `block (3 levels) in <top (required)>').
END
      ret, sout, serr = run(@testfile)
      test_eq? ret, 1
      test_eq? serr, expected
    end

    test_subject "[!bzgiw] returns total number of failures and errors." do
      ret, sout, serr = run(@testfile)
      test_eq? ret, 2    # 1 failure, 1 error
    end

    test_subject "[!937kw] recovers 'Config.color_enabled' value." do
      bkup = Oktest::Config.color_enabled
      begin
        [true, false].each do |bool|
          ["on", "off"].each do |flag|
            Oktest::Config.color_enabled = bool
            run(@testfile, "--color=#{flag}")
            test_eq? Oktest::Config.color_enabled, bool
          end
        end
      ensure
        Oktest::Config.color_enabled = bkup
      end
    end

  end

  test_target 'Oktest::MainApp#skeleton()' do
    test_subject "[!s2i1p] returns skeleton string of test script." do
      str = Oktest::MainApp.new.__send__(:skeleton)
      test_ok? str =~ /^require 'oktest'$/
      test_ok? str =~ /^Oktest\.scope do$/
    end
    test_subject "[!opvik] skeleton string is valid ruby code." do
      str = Oktest::MainApp.new.__send__(:skeleton)
      filename = "tmp.skeleton.rb"
      File.write(filename, str, encoding: 'utf-8')
      begin
        result = `ruby -wc #{filename}`  # may reports warning
        test_eq? result, "Syntax OK\n"
      ensure
        File.unlink filename
      end
    end
  end

end
