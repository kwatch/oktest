###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class MainApp_TC < TC

  def setup
    @testfile = "_tmp_test.rb"
    File.write(@testfile, INPUT, encoding: 'utf-8')
  end

  def teardown
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
    output = output.sub(/\(in \d+\.\d\d\ds\)/, '(in 0.000s)')
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

    it "returns 0 when no errors raised." do
      ret, sout, serr = main(["-h"])
      assert_eq ret, 0
      assert_eq serr, ""
    end

    it "returns 1 when a certain error raised." do
      ret, sout, serr = main(["-U"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -U: unknown option.\n"
    end

    it "reports error when unknown option specified." do
      ret, sout, serr = main(["-X"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -X: unknown option.\n"
      #
      ret, sout, serr = main(["--foobar"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: --foobar: unknown option.\n"
    end

    it "reports error when required argument is missing." do
      ret, sout, serr = main(["-s"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -s: argument required.\n"
    end

    it "reports error when argument is invalid." do
      ret, sout, serr = main(["-s", "foobar"])
      assert_eq ret, 1
      assert_eq serr, "#{File.basename($0)}: -s foobar: invalid argument.\n"
    end

  end


  describe '#run()' do

    def run(*args)
      ret = nil
      sout, serr = capture do
        ret = Oktest::MainApp.new.run(*args)
      end
      return ret, sout, serr
    end

    it "runs test scripts." do
      expected = <<'END'
## total:8, <G>pass:4</G>, <R>fail:1</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>  (in 0.000s)
END
      ret, sout, serr = run(@testfile)
      assert_eq ret, 2
      assert edit_actual(sout).end_with?(edit_expected(expected)), "invalid status line"
    end

    it "finds test scripts in directory and runs them." do
      expected = <<'END'
## total:8, <G>pass:4</G>, <R>fail:1</R>, <R>error:1</R>, <Y>skip:1</Y>, <Y>todo:1</Y>  (in 0.000s)
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

    it "'-h' or '--help' option prints help message." do
      expected = <<END
Usage: #{File.basename($0)} [<options>] [<file-or-directory>...]
  -h, --help    : show help
      --version : print version
  -s STYLE      : report style (verbose/simple/plain, or v/s/p)
  -g, --generate: generate test code from source file
END
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

    it "'--version' option prints version number." do
      expected = <<END
0.0.0
END
      #
      ret, sout, serr = run("--version")
      assert_eq ret, 0
      assert_eq sout, expected
      assert_eq serr, ""
    end

    it "'-s verbose' or '-sv' option prints test results in verbose mode." do
      expected = <<END
* <b>Parent</b>
  * <b>Child1</b>
    - [<G>pass</G>] 1+1 should be 2
    - [<G>pass</G>] 1-1 should be 0
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

    it "'-s simple' or '-ss' option prints test results in simple mode." do
      expected = <<END
#{@testfile}: <G>.</G><G>.</G><R>f</R><R>E</R><Y>s</Y><Y>t</Y><G>.</G><G>.</G>
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

    it "'-s plain' or '-sp' option prints test results in plain mode." do
      expected = <<END
<G>.</G><G>.</G><R>f</R><R>E</R><Y>s</Y><Y>t</Y><G>.</G><G>.</G>
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

    it "'-g' or '--generate' option prints test code." do
      input = <<'END'
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
      filename = "_tmpcode_4674.rb"
      File.write(filename, input)
      expected = <<END
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello' do
      spec "default name is 'world'."
      spec "returns greeting message."
    end


  end # Hello


end
END
      #
      begin
        ret, sout, serr = run("-g", filename)
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

  end


end
