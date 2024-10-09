# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


class DummyUser
  def initialize(id, name)
    @id = id
    @name = name
  end
  attr_accessor :id, :name
end


class SpecHelper__Test
  extend NanoTest
  extend Oktest::SpecHelper

  def self.test_subject(desc, &b)
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::AssertionObject::NOT_YET.clear()
    @__at_end_blocks = nil
  end

  test_target 'Oktest::SpecHelper#ok()' do
    test_subject "[!3jhg6] creates new assertion object." do
      o = ok {"foo"}
      test_eq? o.class, Oktest::AssertionObject
      test_eq? o.actual, "foo"
      test_eq? o.bool, true
    end
    test_subject "[!bc3l2] records invoked location." do
      lineno = __LINE__ + 1
      o = ok {"bar"}
      test_ok? o.location.to_s.start_with?("#{__FILE__}:#{lineno}:")
    end
    test_subject "[!mqtdy] not record invoked location when `Config.ok_location == false`." do
      bkup = Oktest::Config.ok_location
      begin
        Oktest::Config.ok_location = false
        o = ok {"bar"}
        test_eq? o.location, nil
      ensure
        Oktest::Config.ok_location = bkup
      end
    end
  end

  test_target 'Oktest::SpecHelper#not_ok()' do
    test_subject "[!d332o] creates new assertion object for negative condition." do
      o = not_ok {"abc"}
      test_eq? o.class, Oktest::AssertionObject
      test_eq? o.actual, "abc"
      test_eq? o.bool, false
    end
    test_subject "[!agmx8] records invoked location." do
      lineno = __LINE__ + 1
      o = not_ok {"bar"}
      test_ok? o.location.to_s.start_with?("#{__FILE__}:#{lineno}:")
    end
    test_subject "[!a9508] not record invoked location when `Config.ok_location == false`." do
      bkup = Oktest::Config.ok_location
      begin
        Oktest::Config.ok_location = false
        o = not_ok {"bar"}
        test_eq? o.location, nil
      ensure
        Oktest::Config.ok_location = bkup
      end
    end
  end

  test_target 'Oktest::SpecHelper#skip_when()' do
    test_subject "[!3xqf4] raises SkipException if condition is truthy." do
      exc = test_exception? Oktest::SkipException do
        skip_when (1+1 == 2), "..reason.."
      end
      test_eq? exc.message, "..reason.."
    end
    test_subject "[!r7cxx] not raise nothing if condition is falsy." do
      begin
        skip_when (1+1 == 0), "..reason.."
      rescue Exception => exc
        test_ok? false, "nothing should be raised but #{exc.class} raised"
      else
        test_ok? true, msg: "OK"
      end
    end
  end

  test_target 'Oktest::SpecHelper#fixture()' do
    test_subject "[!m4ava] calls fixture block and returns result of it." do
      val = nil
      Oktest.scope() do
        topic 'Example' do
          fixture :foo do "<<foo>>" end
          spec 'sample' do
            val = fixture(:foo)
          end
        end
      end
      capture_output! { Oktest.run() }
      test_eq? val, "<<foo>>"
    end
    test_subject "[!zgfg9] finds fixture block in current or parent node." do
      val1 = val2 = val3 = nil
      Oktest.scope() do
        fixture :foo do "<<foo>>" end
        topic 'Outer' do
          fixture :bar do "<<bar>>" end
          topic 'Inner' do
            fixture :baz do "<<baz>>" end
            spec 'sample' do
              val1 = fixture(:baz)
              val2 = fixture(:bar)
              val3 = fixture(:foo)
            end
          end
        end
      end
      capture_output! { Oktest.run() }
      test_eq? val1, "<<baz>>"
      test_eq? val2, "<<bar>>"
      test_eq? val3, "<<foo>>"
    end
    test_subject "[!l2mcx] accepts block arguments." do
      val = nil
      Oktest.scope() do
        fixture :foo do |x, y, z: 0|
          {x: x, y: y, z: z}
        end
        topic 'Example' do
          spec 'sample' do
            val = fixture(:foo, 10, 20, z: 30)
          end
        end
      end
      capture_output! { Oktest.run() }
      test_eq? val, {x: 10, y: 20, z: 30}
    end
    test_subject "[!wxcsp] raises error when fixture not found." do
      exc = nil
      Oktest.scope() do
        fixture :foo do "<<foo>>" end
        topic 'Example' do
          spec 'sample' do
            begin
              fixture(:bar)
            rescue Exception => exc
            end
          end
        end
      end
      capture_output! { Oktest.run() }
      test_eq? exc.class, Oktest::FixtureNotFoundError
      test_eq? exc.message, "`:bar`: fixture not found."
    end
  end

  test_target 'Oktest::SpecHelper#at_end()' do
    test_subject "[!x58eo] records clean-up block." do
      Oktest.scope() do
        topic 'Example' do
          spec 'sample #1' do
            puts "before at_end()"
            at_end { puts "in at_end()" }
            puts "after at_end()"
          end
        end
      end
      sout, serr = capture_output! { Oktest.run() }
      expected = <<'END'
before at_end()
after at_end()
in at_end()
END
      test_ok? sout.include?(expected), msg: "not matched"
    end
  end

  test_target 'Oktest::SpecHelper#capture_stdio()' do
    test_subject "[!1kbnj] captures $stdio and $stderr." do
      sout, serr = capture_stdio() do
        puts "fooo"
        $stderr.puts "baaa"
      end
      test_eq? sout, "fooo\n"
      test_eq? serr, "baaa\n"
    end
    test_subject "[!53mai] takes $stdin data." do
      data = nil
      sout, serr = capture_stdio("blabla") do
        data = $stdin.read()
      end
      data = "blabla"
    end
    test_subject "[!wq8a9] recovers stdio even when exception raised." do
      stdin_, stdout_, stderr_ = $stdin, $stdout, $stderr
      exception = nil
      begin
        sout, serr = capture_stdio() do
          puts "fooo"
          $stderr.puts "baaa"
          test_ok? stdin_  != $stdin , msg: "stdin should be replaced"
          test_ok? stdout_ != $stdout, msg: "stdout should be replaced"
          test_ok? stderr_ != $stderr, msg: "stderr should be replaced"
          1/0    # ZeroDivisionError
        end
      rescue ZeroDivisionError => exc
        exception = exc
      end
      test_ok? exception != nil,  msg: "exception should be raised."
      test_ok? exception.is_a?(ZeroDivisionError), msg: "ZeroDivisionError should be raised."
      test_ok? stdin_  == $stdin , msg: "stdin should be recovered"
      test_ok? stdout_ == $stdout, msg: "stdout should be recovered"
      test_ok? stderr_ == $stderr, msg: "stderr should be recovered"
    end
    test_subject "[!4j494] returns outpouts of stdout and stderr." do
      sout, serr = capture_stdio() do
        puts "foo"
        $stderr.puts "bar"
      end
      test_eq? sout, "foo\n"
      test_eq? serr, "bar\n"
    end
    test_subject "[!6ik8b] can simulate tty." do
      sout, serr = capture_stdio() do
        test_eq? $stdin.tty?, false
        test_eq? $stdout.tty?, false
        test_eq? $stderr.tty?, false
      end
      #
      sout, serr = capture_stdio(tty: true) do
        test_eq? $stdin.tty?, true
        test_eq? $stdout.tty?, true
        test_eq? $stderr.tty?, true
      end
    end
  end

  test_target 'Oktest::SpecHelper#capture_sio()' do
    test_subject "[!qjmaa] 'capture_sio()' is an alias of 'capture_stdio()'." do
      sin = nil
      sout, serr = capture_sio("INPUT", tty: true) do
        sin = $stdin.read()
        puts "OUTPUT"
        $stderr.puts "ERROR"
        test_eq? $stdin.tty?, true
        test_eq? $stdout.tty?, true
        test_eq? $stdout.tty?, true
      end
      test_eq? sin, "INPUT"
      test_eq? sout, "OUTPUT\n"
      test_eq? serr, "ERROR\n"
    end
  end

  test_target 'Oktest::SpecHelper#capture_stdout()' do
    test_subject "[!4agii] same as `sout, serr = capture_stdio(); ok {serr} == ''`." do
      sin = nil
      sout = capture_stdout("INPUT", tty: true) do
        sin = $stdin.read()
        puts "OUTPUT"
        test_eq? $stdin.tty?, true
        test_eq? $stdout.tty?, true
        test_eq? $stderr.tty?, true
      end
      test_eq? sin, "INPUT"
      test_eq? sout, "OUTPUT\n"
    end
    test_subject "[!may84] fails when stderr is not empty." do
      exc = test_exception? Oktest::AssertionFailed do
        capture_stdout() do
          $stderr.print "ERROR"
        end
      end
      test_eq? exc.message, "Output of $stderr expected to be empty, but got: \"ERROR\""
    end
    test_subject "[!5n04e] returns output of stdout." do
      sout = capture_stdout() do
        print "OUTPUT"
      end
      test_eq? sout, "OUTPUT"
    end
  end

  test_target 'Oktest::SpecHelper#capture_stderr()' do
    test_subject "[!46tj4] same as `sout, serr = capture_stdio(); ok {sout} == ''`." do
      sin = nil
      serr = capture_stderr("INPUT", tty: true) do
        sin = $stdin.read()
        $stderr.puts "ERROR"
        test_eq? $stdin.tty?, true
        test_eq? $stdout.tty?, true
        test_eq? $stderr.tty?, true
      end
      test_eq? sin, "INPUT"
      test_eq? serr, "ERROR\n"
    end
    test_subject "[!3zh32] fails when stdout is not empty." do
      exc = test_exception? Oktest::AssertionFailed do
        capture_stderr() do
          print "OUTPUT"
        end
      end
      test_eq? exc.message, "Output of $stdout expected to be empty, but got: \"OUTPUT\""
    end
    test_subject "[!5vs64] returns output of stderr." do
      serr = capture_stderr() do
        $stderr.print "ERROR"
      end
      test_eq? serr, "ERROR"
    end
  end

  test_target 'Oktest::SpecHelper#capture_command()' do
    test_subject "[!wyp17] executes command with stdin data." do
      sout, serr = capture_command("cat -n", "AAA\nBBB\n")
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
    end
    test_subject "[!jd63p] raises error if command failed." do
      begin
        capture_command("ls *not*exist*")
      rescue => exc
        test_eq? exc.class, RuntimeError
        test_eq? exc.message, "Command failed with status (1): `ls *not*exist*`"
      else
        test_ok? false, msg: "Exception should be raised but not."
      end
    end
    test_subject "[!lsmgq] calls error handler block if command failed." do
      called = nil
      sout, serr = capture_command("ls *not*exist*") do |pstat|
        called = pstat
      end
      test_ok? called.is_a?(Process::Status)
      test_ok? called.exitstatus == 1
      test_eq? sout, ""
      test_eq? serr, "ls: *not*exist*: No such file or directory\n"
    end
    test_subject "[!vivq3] doesn't call error handler block if command finished successfully." do
      called = false
      sout, serr = capture_command("cat -n", "AAA\nBBB\n") do
        called = true
      end
      test_eq? called, false
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
    end
    test_subject "[!nxw59] not raise error if command failed and error handler specified." do
      begin
        sout, serr = capture_command("ls *not*exist*") do end
      rescue => exc
        test_ok? false, msg: "Exception should not raised, but raised #{exc.inspect}"
      end
      test_eq? sout, ""
      test_eq? serr, "ls: *not*exist*: No such file or directory\n"
    end
    test_subject "[!h5994] returns output of stdin and stderr." do
      sout, serr = capture_command("cat -n", "AAA\nBBB\n")
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
      #
      sout, serr = capture_command("echo ERR >&2")
      test_eq? sout, ""
      test_eq? serr, "ERR\n"
    end
  end

  test_target 'Oktest::SpecHelper#capture_command!()' do
    test_subject "[!vlbpo] executes command with stdin data." do
      sout, serr = capture_command!("cat -n", "AAA\nBBB\n")
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
    end
    test_subject "[!yfohb] not raise error even if command failed." do
      sout, serr = capture_command!("ls *not*exist*")
      test_eq? sout, ""
      test_eq? serr, "ls: *not*exist*: No such file or directory\n"
    end
    test_subject "[!andyj] calls error handler block if command failed." do
      called = nil
      sout, serr = capture_command!("ls *not*exist*") do |pstat|
        called = pstat
      end
      test_ok? called.is_a?(Process::Status)
      test_ok? called.exitstatus == 1
      test_eq? sout, ""
      test_eq? serr, "ls: *not*exist*: No such file or directory\n"
    end
    test_subject "[!xnkqc] doesn't call error handler block if command finished successfully." do
      called = false
      sout, serr = capture_command!("cat -n", "AAA\nBBB\n") do
        called = true
      end
      test_eq? called, false
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
    end
    test_subject "[!3xdgo] returns output of stdin and stderr." do
      sout, serr = capture_command!("cat -n", "AAA\nBBB\n")
      test_eq? sout, "     1\tAAA\n     2\tBBB\n"
      test_eq? serr, ""
      #
      sout, serr = capture_command!("echo ERR >&2")
      test_eq? sout, ""
      test_eq? serr, "ERR\n"
    end
  end

  test_target 'Oktest::SpecHelper#dummy_file()' do
    test_subject "[!7e0bo] creates dummy file." do
      tmpfile = "_tmp_3511.txt"
      File.unlink(tmpfile) if File.exist?(tmpfile)
      begin
        dummy_file(tmpfile, "foobar")
        test_ok? File.exist?(tmpfile), msg: "tmpfile should be created."
        test_eq? @__at_end_blocks.length, 1
        pr = @__at_end_blocks.pop()
        pr.call()
        test_ok? !File.exist?(tmpfile), msg: "tmpfile should be removed."
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    test_subject "[!yvfxq] raises error when dummy file already exists." do
      tmp = "_tmp_4883.txt"
      [true, false].each do |flag|
        begin
          flag ? File.write(tmp, "") : Dir.mkdir(tmp)
          exc = test_exception? ArgumentError do
            dummy_file(tmp, "foobar")
          end
          test_eq? exc.message, "dummy_file('#{tmp}'): temporary file already exists."
        ensure
          File.unlink(tmp) if File.file?(tmp)
          Dir.rmdir(tmp)   if File.directory?(tmp)
        end
      end
    end
    test_subject "[!nvlkq] returns filename." do
      tmpfile = "_tmp_4947.txt"
      begin
        ret = dummy_file(tmpfile, "foobar")
        test_eq? ret, tmpfile
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    test_subject "[!3mg26] generates temporary filename if 1st arg is nil." do
      begin
        tmpfile1 = dummy_file(nil, "foobar")
        tmpfile2 = dummy_file(nil, "foobar")
        test_ok? tmpfile1 =~ /^_tmpfile_\d{6}/, msg: "tempoary filename should be generated."
        test_ok? tmpfile2 =~ /^_tmpfile_\d{6}/, msg: "tempoary filename should be generated."
        test_ok? tmpfile1 != tmpfile2, msg: "tempoary filename should contain random number."
      ensure
        File.unlink(tmpfile1) if File.exist?(tmpfile1)
        File.unlink(tmpfile2) if File.exist?(tmpfile2)
      end
    end
    test_subject "[!ky7nh] can take block argument." do
      tmpfile = "_tmp_9080"
      begin
        ret = dummy_file(tmpfile) do |filename|
          test_eq? filename, tmpfile
          test_ok? File.file?(tmpfile), msg: "tmpfile should be created."
          1234
        end
        test_ok? !File.file?(tmpfile), msg: "tmpfile should be removed."
        test_eq? ret, 1234
        test_eq? @__at_end_blocks, nil
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
  end

  test_target 'Oktest::SpecHelper#dummy_dir()' do
    test_subject "[!l34d5] creates dummy directory." do
      tmpdir = "_tmpdir_7903"
      Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      begin
        dummy_dir(tmpdir)
        test_ok? File.exist?(tmpdir), msg: "tmpdir should be created."
        test_eq? @__at_end_blocks.length, 1
        pr = @__at_end_blocks.pop()
        pr.call()
        test_ok? !File.exist?(tmpdir), msg: "tmpdir should be removed."
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    test_subject "[!zypj6] raises error when dummy dir already exists." do
      tmp = "_tmpdir_1062"
      [true, false].each do |flag|
        begin
          flag ? Dir.mkdir(tmp) : File.write(tmp, "")
          exc = test_exception? ArgumentError do
            dummy_dir(tmp)
          end
          test_eq? exc.message, "dummy_dir('#{tmp}'): temporary directory already exists."
        ensure
          Dir.rmdir(tmp)   if File.directory?(tmp)
          File.unlink(tmp) if File.file?(tmp)
        end
      end
    end
    test_subject "[!01gt7] removes dummy directory even if test_subject contains other files." do
      tmpdir = "_tmpdir_3869"
      begin
        dummy_dir(tmpdir)
        File.write("#{tmpdir}/foo.txt", "foofoo", encoding: 'utf-8')
        Dir.mkdir("#{tmpdir}/d1")
        Dir.mkdir("#{tmpdir}/d1/d2")
        File.write("#{tmpdir}/d1/d2/bar.txt", "barbar", encoding: 'utf-8')
        test_ok? File.exist?("#{tmpdir}/foo.txt"), msg: "should exists."
        test_ok? File.exist?("#{tmpdir}/d1/d2/bar.txt"), msg: "should exists."
        #
        pr = @__at_end_blocks.pop()
        pr.call()
        test_ok? !File.exist?(tmpdir), msg: "tmpdir should be removed."
      ensure
        FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
      end
    end
    test_subject "[!jxh30] returns directory name." do
      tmpdir = "_tmpdir_2546"
      begin
        ret = dummy_dir(tmpdir)
        test_eq? ret, tmpdir
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    test_subject "[!r14uy] generates temporary directory name if 1st arg is nil." do
      begin
        tmpdir1 = dummy_dir(nil)
        tmpdir2 = dummy_dir()
        test_ok? tmpdir1 =~ /^_tmpdir_\d{6}/, msg: "tempoary directory name should be generated."
        test_ok? tmpdir2 =~ /^_tmpdir_\d{6}/, msg: "tempoary directory name should be generated."
        test_ok? tmpdir1 != tmpdir2, msg: "tempoary directory name should contain random number."
      ensure
        Dir.rmdir(tmpdir1) if File.exist?(tmpdir1)
        Dir.rmdir(tmpdir2) if File.exist?(tmpdir2)
      end
    end
    test_subject "[!tfsqo] can take block argument." do
      tmpdir = "_tmp_5799"
      begin
        ret = dummy_dir(tmpdir) do |dirname|
          test_eq? dirname, tmpdir
          test_ok? File.directory?(tmpdir), msg: "tmpdir should be created."
          2345
        end
        test_ok? !File.directory?(tmpdir), msg: "tmpdir should be removed."
        test_eq? ret, 2345
        test_eq? @__at_end_blocks, nil
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
  end

  test_target 'Oktest::SpecHelper#dummy_values()' do
    test_subject "[!hgwg2] changes hash value temporarily." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      test_eq? hashobj[:a], 1000
      test_eq? hashobj['b'], 2000
      test_eq? hashobj[:c], 30
      test_eq? hashobj[:x], 9000
    end
    test_subject "[!jw2kx] recovers hash values." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      test_eq? hashobj[:a], 1000
      test_eq? hashobj['b'], 2000
      test_eq? hashobj[:c], 30
      test_eq? hashobj[:x], 9000
      test_eq? @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      test_eq? hashobj[:a], 10
      test_eq? hashobj['b'], 20
      test_eq? hashobj[:c], 30
      test_ok? !hashobj.key?(:x), msg: "key :x should not exist."
    end
    test_subject "[!w3r0p] returns keyvals." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      ret = dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      test_eq? ret, {:a=>1000, 'b'=>2000, :x=>9000}
    end
    test_subject "[!pwq6v] can take block argument." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      ret = dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000) do |kvs|
        test_eq? hashobj[:a], 1000
        test_eq? hashobj['b'], 2000
        test_eq? hashobj[:c], 30
        test_eq? hashobj[:x], 9000
        test_eq? kvs, {:a=>1000, 'b'=>2000, :x=>9000}
        5678
      end
      test_eq? ret, 5678
      test_eq? hashobj[:a], 10
      test_eq? hashobj['b'], 20
      test_eq? hashobj[:c], 30
      test_ok? !hashobj.key?(:x), msg: "key :x should not exist."
      test_eq? @__at_end_blocks, nil
    end
  end

  test_target 'Oktest::SpecHelper#dummy_attrs()' do
    test_subject "[!4vd73] changes object attributes temporarily." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      test_eq? obj.id, 999
      test_eq? obj.name, "bob"
    end
    test_subject "[!fi0t3] recovers attribute values." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      test_eq? obj.id, 999
      test_eq? obj.name, "bob"
      #
      test_eq? @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      test_eq? obj.id, 123
      test_eq? obj.name, "alice"
    end
    test_subject "[!27yeh] returns keyvals." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>789, :name=>"charlie")
      test_eq? ret, {:id=>789, :name=>"charlie"}
    end
    test_subject "[!j7tvp] can take block argument." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>888, :name=>"dave") do |kvs|
        test_eq? obj.id, 888
        test_eq? obj.name, "dave"
        test_eq? kvs, {:id=>888, :name=>"dave"}
        4567
      end
      test_eq? ret, 4567
      test_eq? obj.id, 123
      test_eq? obj.name, "alice"
      test_eq? @__at_end_blocks, nil
    end
  end

  test_target 'Oktest::SpecHelper#dummy_ivars()' do
    test_subject "[!rnqiv] changes instance variables temporarily." do
      obj = DummyUser.new(123, "alice")
      dummy_ivars(obj, :id=>999, :name=>"bob")
      test_eq? obj.instance_variable_get('@id'), 999
      test_eq? obj.instance_variable_get('@name'), "bob"
    end
    test_subject "[!8oirn] recovers instance variables." do
      obj = DummyUser.new(123, "alice")
      dummy_ivars(obj, :id=>999, :name=>"bob")
      test_eq? obj.instance_variable_get('@id'), 999
      test_eq? obj.instance_variable_get('@name'), "bob"
      #
      test_eq? @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      test_eq? obj.instance_variable_get('@id'), 123
      test_eq? obj.instance_variable_get('@name'), "alice"
    end
    test_subject "[!01dc8] returns keyvals." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_ivars(obj, :id=>789, :name=>"charlie")
      test_eq? ret, {:id=>789, :name=>"charlie"}
    end
    test_subject "[!myzk4] can take block argument." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>888, :name=>"dave") do |kvs|
        test_eq? obj.instance_variable_get('@id'), 888
        test_eq? obj.instance_variable_get('@name'), "dave"
        test_eq? kvs, {:id=>888, :name=>"dave"}
        4567
      end
      test_eq? ret, 4567
      test_eq? obj.id, 123
      test_eq? obj.name, "alice"
      test_eq? @__at_end_blocks, nil
    end
  end

  test_target 'Oktest::SpecHelper#recorder()' do
    test_subject "[!qwrr8] loads 'benry/recorder' automatically." do
      if defined?(Benry::Recorder)
        $stderr.puts "** skip because 'benry/recorder' already loaded."
      else
        test_ok? !defined? Benry::Recorder, msg: "should not be loaded."
        recorder()
        test_ok? !!defined? Benry::Recorder, msg: "should be loaded."
      end
    end
    test_subject "[!glfvx] creates Benry::Recorder object." do
      rec = recorder()
      test_ok? rec.is_a?(Benry::Recorder)
      o = rec.fake_object(:foo=>123)
      test_eq? o.foo(), 123
      test_eq? rec[0].name, :foo
      test_eq? rec[0].obj, o
    end
  end

end
