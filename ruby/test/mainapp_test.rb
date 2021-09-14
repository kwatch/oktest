###
### $Release: 1.1.1 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class MainApp_TC < TC

  def setup
    @testfile = "_tmp_test.rb"
    File.write(@testfile, INPUT, encoding: 'utf-8')
    @_color_enabled = Oktest::Config.color_enabled
    Oktest::Config.color_enabled = true
  end

  def teardown
    Oktest::Config.color_enabled = @_color_enabled
    File.unlink(@testfile)
  end

  INPUT = <<'END'
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


  describe '.main()' do

    def main(argv)
      ret = nil
      sout, serr = capture do
        ret = Oktest::MainApp.main(argv)
      end
      return ret, sout, serr
    end

    it "[!tb6sx] returns 0 when no errors raised." do
      ret, sout, serr = main(["-h"])
      assert_eq ret, 0
      assert_eq serr, ""
    end

    it "[!d5mql] returns 1 when a certain error raised." do
      ret, sout, serr = main(["-U"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -U: unknown option.\n"
    end

    it "[!jr49p] reports error when unknown option specified." do
      ret, sout, serr = main(["-X"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -X: unknown option.\n"
      #
      ret, sout, serr = main(["--foobar"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: --foobar: unknown option.\n"
    end

    it "[!uqomj] reports error when required argument is missing." do
      ret, sout, serr = main(["-s"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -s: argument required.\n"
    end

    it "[!8i755] reports error when argument is invalid." do
      ret, sout, serr = main(["-s", "foobar"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -s foobar: invalid argument.\n"
      #
      ret, sout, serr = main(["-F", "aaa=*pat*"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -F aaa=*pat*: invalid argument.\n"
      #
      ret, sout, serr = main(["--color=true"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: --color=true: invalid argument.\n"
    end

  end


  describe '#run()' do

    def run(*args, tty: true)
      ret = nil
      sout, serr = capture("", tty: tty) do
        ret = Oktest::MainApp.new.run(*args)
      end
      return ret, sout, serr
    end

    it "[!18qpe] runs test scripts." do
      expected = <<'END'
## total:8 (<B>pass:4</B>, <R>fail:1</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      ret, sout, serr = run(@testfile)
      assert_eq ret, 2
      assert edit_actual(sout).end_with?(edit_expected(expected)), "invalid status line"
    end

    it "[!bim36] changes auto-running to off." do
      Oktest::Config.auto_run = true
      _ = run(@testfile)
      assert_eq Oktest::Config.auto_run, false
    end

    it "[!hiu5b] finds test scripts in directory and runs them." do
      expected = <<'END'
## total:8 (<B>pass:4</B>, <R>fail:1</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      dir = "_tmpdir.d"
      dirs = [dir, "#{dir}/d1", "#{dir}/d1/d2"]
      dirs.each {|x| Dir.mkdir(x) unless File.directory?(x) }
      File.rename(@testfile, "#{dir}/d1/d2/#{@testfile}")
      begin
        ret, sout, serr = run(dir)
        assert_eq ret, 2
        assert edit_actual(sout).end_with?(edit_expected(expected)), "invalid status line"
      ensure
        File.rename("#{dir}/d1/d2/#{@testfile}", @testfile)
        dirs.reverse.each {|x| Dir.rmdir(x) }
      end
    end

    #HELP_MESSAGE = Oktest::MainApp::HELP_MESSAGE % {command: File.basename($0)}
    HELP_MESSAGE = <<"END"
Usage: #{File.basename($0)} [<options>] [<file-or-directory>...]
  -h, --help             : show help
      --version          : print version
  -s <REPORT-STYLE>      : verbose/simple/compact/plain/quiet, or v/s/c/p/q
  -F <PATTERN>           : filter topic or spec with pattern (see below)
      --color[={on|off}] : enable/disable output coloring forcedly
  -C, --create           : print test code skeleton
  -G, --generate         : generate test code skeleton from ruby file
      --faster           : make 'ok{}' faster (for very large project)

Filter examples:
  $ oktest -F topic=Hello            # filter by topic
  $ oktest -F spec='*hello*'         # filter by spec
  $ oktest -F tag=name               # filter by tag name
  $ oktest -F tag!=name              # negative filter by tag name
  $ oktest -F tag='{name1,name2}'    # filter by multiple tag names

See https://github.com/kwatch/oktest/blob/ruby/ruby/README.md for details.
END

    it "[!65vdx] prints help message if no arguments specified." do
      expected = HELP_MESSAGE
      ret, sout, serr = run()
      assert_eq ret, 0
      assert_eq sout, expected
      assert_eq serr, ""
    end

    it "[!9973n] '-h' or '--help' option prints help message." do
      expected = HELP_MESSAGE
      #
      ret, sout, serr = run("-h")
      assert_eq ret, 0
      assert_eq sout, expected
      assert_eq serr, ""
      #
      ret, sout, serr = run("--help")
      assert_eq ret, 0
      assert_eq sout, expected
      assert_eq serr, ""
    end

    it "[!qqizl] '--version' option prints version number." do
      expected = '$Release: 1.1.1 $'.split()[1] + "\n"
      #
      ret, sout, serr = run("--version")
      assert_eq ret, 0
      assert_eq sout, expected
      assert_eq serr, ""
    end

    it "[!0qd92] '-s verbose' or '-sv' option prints test results in verbose mode." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<B>pass</B>] 1+1 should be 2
    - [<B>pass</B>] 1-1 should be 0
  * <b>Child2</b>
    - [<R>Fail</R>] 1*1 should be 1
    - [<R>ERROR</R>] 1/1 should be 1
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sv", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
      #
      ret, sout, serr = run("-s", "verbose", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
    end

    it "[!zfdr5] '-s simple' or '-ss' option prints test results in simple mode." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>: <B>.</B><B>.</B>
  * <b>Child1</b>: <B>.</B><B>.</B>
  * <b>Child2</b>: <R>f</R><R>E</R>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-ss", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
      #
      ret, sout, serr = run("-s", "simple", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
    end

    it "[!ef5v7] '-s compact' or '-sc' option prints test results in compact mode." do
      expected = <<END
#{@testfile}: <B>.</B><B>.</B><R>f</R><R>E</R><Y>s</Y><Y>t</Y><B>.</B><B>.</B>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sc", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
      #
      ret, sout, serr = run("-s", "compact", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
    end

    it "[!244te] '-s plain' or '-sp' option prints test results in plain mode." do
      expected = <<END
<B>.</B><B>.</B><R>f</R><R>E</R><Y>s</Y><Y>t</Y><B>.</B><B>.</B>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sp", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
      #
      ret, sout, serr = run("-s", "plain", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
    end

    it "[!ai61w] '-s quiet' or '-sq' option prints test results in quiet mode." do
      expected = <<END
<R>f</R><R>E</R><Y>s</Y><Y>t</Y>
----------------------------------------------------------------------
END
      #
      ret, sout, serr = run("-sq", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
      #
      ret, sout, serr = run("-s", "quiet", @testfile)
      assert_eq ret, 2
      assert edit_actual(sout).start_with?(edit_expected(expected)), "invalid testcase output"
      assert_eq serr, ""
    end

    it "[!yz7g5] '-F topic=...' option filters topics." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<B>pass</B>] 1+1 should be 2
    - [<B>pass</B>] 1-1 should be 0
## total:2 (<B>pass:2</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "topic=Child1", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!ww2mp] '-F spec=...' option filters specs." do
      expected = <<END
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<B>pass</B>] 1-1 should be 0
## total:1 (<B>pass:1</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "spec=*1-1*", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!8uvib] '-F tag=...' option filters by tag name." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<B>pass</B>] 1-1 should be 0
  * <b>Child3</b>
    - [<Y>Skip</Y>] skip example <Y>(reason: a certain condition)</Y>
    - [<Y>TODO</Y>] todo example
  - <b>When x is negative</b>
    - [<B>pass</B>] [!6hs1j] x*x is positive.
## total:4 (<B>pass:2</B>, fail:0, error:0, <Y>skip:1</Y>, <Y>todo:1</Y>) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag={new,exp}", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!m0iwm] '-F sid=...' option filters by spec id." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  - <b>When x is negative</b>
    - [<B>pass</B>] [!6hs1j] x*x is positive.
## total:1 (<B>pass:1</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "sid=6hs1j", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!noi8i] '-F' option supports negative filter." do
      expected = <<'END'
## _tmp_test.rb
* <b>Parent</b>
  * <b>Child1</b>
    - [<B>pass</B>] 1+1 should be 2
    - [<B>pass</B>] 1-1 should be 0
  - <b>Else</b>
    - [<B>pass</B>] [!pwiq7] x*x is also positive.
## total:3 (<B>pass:3</B>, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag!={fail,err,exp}", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!71h2x] '-F ...' option will be error." do
      assert_exc(OptionParser::InvalidArgument, "invalid argument: -F *pat*") do
        run("-F", "*pat*", @testfile)
      end
    end

    it "[!j01y7] if filerting by '-F' matched nothing, then prints zero result." do
      expected = <<'END'
## total:0 (pass:0, fail:0, error:0, skip:0, todo:0) in 0.000s
END
      #
      ret, sout, serr = run("-F", "tag=blablabla", @testfile)
      assert_eq ret, 0
      assert_eq edit_actual(sout), edit_expected(expected)
      assert_eq serr, ""
    end

    it "[!6ro7j] '--color=on' option enables output coloring forcedly." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color=on", @testfile, tty: tty)
          assert sout.include?(edit_expected("[<B>pass</B>]")), "should contain blue string"
          assert sout.include?(edit_expected("[<R>Fail</R>]")), "should contain red string"
          assert sout.include?(edit_expected("[<Y>Skip</Y>]")), "should contain yellos string"
          assert_eq serr, ""
        end
      end
    end

    it "[!dptgn] '--color' is same as '--color=on'." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color", @testfile, tty: tty)
          assert sout.include?(edit_expected("[<B>pass</B>]")), "should contain blue string"
          assert sout.include?(edit_expected("[<R>Fail</R>]")), "should contain red string"
          assert sout.include?(edit_expected("[<Y>Skip</Y>]")), "should contain yellos string"
          assert_eq serr, ""
        end
      end
    end

    it "[!vmw0q] '--color=off' option disables output coloring forcedly." do
      [true, false].each do |bool|
        [true, false].each do |tty|
          Oktest::Config.color_enabled = bool
          _, sout, serr = run("--color=off", @testfile, tty: tty)
          assert !sout.include?(edit_expected("[<B>pass</B>]")), "should not contain blue string"
          assert !sout.include?(edit_expected("[<R>Fail</R>]")), "should not contain red string"
          assert !sout.include?(edit_expected("[<Y>Skip</Y>]")), "should not contain yellos string"
          assert_eq serr, ""
        end
      end
    end

    it "[!9nr94] '--color=true' option raises error." do
      assert_exc(OptionParser::InvalidArgument, "invalid argument: --color=true") do
        run("--color=true", @testfile)
      end
    end

    it "[!dk8eg] '-C' or '--create' option prints test code skeleton." do
      ret, sout, serr = run("-C")
      assert_eq ret, 0
      assert_eq sout, Oktest::MainApp::SKELETON
      assert_eq serr, ""
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

    it "[!uxh5e] '-G' or '--generate' option prints test code." do
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

    end  # #hello()


  end  # Hello


end
END
      #
      begin
        ret, sout, serr = run("-G", filename)
        assert_eq ret, 0
        assert_eq sout, expected
        assert_eq serr, ""
        #
        ret, sout, serr = run("--generate", filename)
        assert_eq ret, 0
        assert_eq sout, expected
        assert_eq serr, ""
      ensure
        File.unlink(filename)
      end
    end

    it "[!wmxu5] '--generate=unaryop' option prints test code with unary op." do
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

    end  # #hello()


  end  # Hello


end
END
      #
      begin
        ret, sout, serr = run("-gunaryop", filename)
        assert_eq ret, 0
        assert_eq sout, expected
        assert_eq serr, ""
        #
        ret, sout, serr = run("--generate=unaryop", filename)
        assert_eq ret, 0
        assert_eq sout, expected
        assert_eq serr, ""
      ensure
        File.unlink(filename)
      end
    end

    it "[!qs8ab] '--faster' chanages 'Config.ok_location' to false." do
      assert_eq Oktest::Config.ok_location, true
      begin
        run("--faster", @testfile)
        assert_eq Oktest::Config.ok_location, false
      ensure
        Oktest::Config.ok_location = true
      end
    end

    it "[!dsrae] reports if 'ok()' called but assertion not performed." do
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
      assert_eq ret, 1
      assert_eq serr, expected
    end

    it "[!bzgiw] returns total number of failures and errors." do
      ret, sout, serr = run(@testfile)
      assert_eq ret, 2    # 1 failure, 1 error
    end

    it "[!937kw] recovers 'Config.color_enabled' value." do
      bkup = Oktest::Config.color_enabled
      begin
        [true, false].each do |bool|
          ["on", "off"].each do |flag|
            Oktest::Config.color_enabled = bool
            run(@testfile, "--color=#{flag}")
            assert_eq Oktest::Config.color_enabled, bool
          end
        end
      ensure
        Oktest::Config.color_enabled = bkup
      end
    end

  end

end
