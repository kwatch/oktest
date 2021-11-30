###
### $Release: 1.2.0 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class DummyUser
  def initialize(id, name)
    @id = id
    @name = name
  end
  attr_accessor :id, :name
end


class SpecHelper_TC < TC
  include Oktest::SpecHelper

  def setup()
  end

  def teardown()
    Oktest::AssertionObject::NOT_YET.clear()
  end

  describe '#ok()' do
    it "[!3jhg6] creates new assertion object." do
      o = ok {"foo"}
      assert_eq o.class, Oktest::AssertionObject
      assert_eq o.actual, "foo"
      assert_eq o.bool, true
    end
    it "[!bc3l2] records invoked location." do
      lineno = __LINE__ + 1
      o = ok {"bar"}
      assert o.location.to_s.start_with?("#{__FILE__}:#{lineno}:")
    end
    it "[!mqtdy] not record invoked location when `Config.ok_location == false`." do
      bkup = Oktest::Config.ok_location
      begin
        Oktest::Config.ok_location = false
        o = ok {"bar"}
        assert_eq o.location, nil
      ensure
        Oktest::Config.ok_location = bkup
      end
    end
  end

  describe '#not_ok()' do
    it "[!d332o] creates new assertion object for negative condition." do
      o = not_ok {"abc"}
      assert_eq o.class, Oktest::AssertionObject
      assert_eq o.actual, "abc"
      assert_eq o.bool, false
    end
    it "[!agmx8] records invoked location." do
      lineno = __LINE__ + 1
      o = not_ok {"bar"}
      assert o.location.to_s.start_with?("#{__FILE__}:#{lineno}:")
    end
    it "[!a9508] not record invoked location when `Config.ok_location == false`." do
      bkup = Oktest::Config.ok_location
      begin
        Oktest::Config.ok_location = false
        o = not_ok {"bar"}
        assert_eq o.location, nil
      ensure
        Oktest::Config.ok_location = bkup
      end
    end
  end

  describe '#skip_when()' do
    it "[!3xqf4] raises SkipException if condition is truthy." do
      assert_exc(Oktest::SkipException, "..reason..") do
        skip_when (1+1 == 2), "..reason.."
      end
    end
    it "[!r7cxx] not raise nothing if condition is falsy." do
      begin
        skip_when (1+1 == 0), "..reason.."
      rescue Exception => exc
        assert false, "nothing should be raised but #{exc.class} raised"
      else
        assert true, "OK"
      end
    end
  end

  describe '#fixture()' do
    it "[!m4ava] calls fixture block and returns result of it." do
      val = nil
      Oktest.scope() do
        topic 'Example' do
          fixture :foo do "<<foo>>" end
          spec 'sample' do
            val = fixture(:foo)
          end
        end
      end
      capture { Oktest.run() }
      assert_eq val, "<<foo>>"
    end
    it "[!zgfg9] finds fixture block in current or parent node." do
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
      capture { Oktest.run() }
      assert_eq val1, "<<baz>>"
      assert_eq val2, "<<bar>>"
      assert_eq val3, "<<foo>>"
    end
    it "[!l2mcx] accepts block arguments." do
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
      capture { Oktest.run() }
      assert_eq val, {x: 10, y: 20, z: 30}
    end
    it "[!wxcsp] raises error when fixture not found." do
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
      capture { Oktest.run() }
      assert_eq exc.class, Oktest::FixtureNotFoundError
      assert_eq exc.message, "`:bar`: fixture not found."
    end
  end

  describe '#at_end()' do
    it "[!x58eo] records clean-up block." do
      Oktest.scope() do
        topic 'Example' do
          spec 'sample #1' do
            puts "before at_end()"
            at_end { puts "in at_end()" }
            puts "after at_end()"
          end
        end
      end
      sout, serr = capture { Oktest.run() }
      expected = <<'END'
before at_end()
after at_end()
in at_end()
END
      assert sout.include?(expected), "not matched"
    end
  end

  describe '#capture_sio()' do
    it "[!1kbnj] captures $stdio and $stderr." do
      sout, serr = capture_sio() do
        puts "fooo"
        $stderr.puts "baaa"
      end
      assert_eq sout, "fooo\n"
      assert_eq serr, "baaa\n"
    end
    it "[!53mai] takes $stdin data." do
      data = nil
      sout, serr = capture_sio("blabla") do
        data = $stdin.read()
      end
      data = "blabla"
    end
    it "[!wq8a9] recovers stdio even when exception raised." do
      stdin_, stdout_, stderr_ = $stdin, $stdout, $stderr
      exception = nil
      begin
        sout, serr = capture_sio() do
          puts "fooo"
          $stderr.puts "baaa"
          assert stdin_  != $stdin , "stdin should be replaced"
          assert stdout_ != $stdout, "stdout should be replaced"
          assert stderr_ != $stderr, "stderr should be replaced"
          1/0    # ZeroDivisionError
        end
      rescue ZeroDivisionError => exc
        exception = exc
      end
      assert exception != nil,  "exception should be raised."
      assert exception.is_a?(ZeroDivisionError), "ZeroDivisionError should be raised."
      assert stdin_  == $stdin , "stdin should be recovered"
      assert stdout_ == $stdout, "stdout should be recovered"
      assert stderr_ == $stderr, "stderr should be recovered"
    end
    it "[!4j494] returns outpouts of stdout and stderr." do
      sout, serr = capture_sio() do
        puts "foo"
        $stderr.puts "bar"
      end
      assert_eq sout, "foo\n"
      assert_eq serr, "bar\n"
    end
    it "[!6ik8b] can simulate tty." do
      sout, serr = capture_sio() do
        assert_eq $stdin.tty?, false
        assert_eq $stdout.tty?, false
        assert_eq $stderr.tty?, false
      end
      #
      sout, serr = capture_sio(tty: true) do
        assert_eq $stdin.tty?, true
        assert_eq $stdout.tty?, true
        assert_eq $stderr.tty?, true
      end
    end
  end

  describe '#dummy_file()' do
    it "[!7e0bo] creates dummy file." do
      tmpfile = "_tmp_3511.txt"
      File.unlink(tmpfile) if File.exist?(tmpfile)
      begin
        dummy_file(tmpfile, "foobar")
        assert File.exist?(tmpfile), "tmpfile should be created."
        assert_eq @__at_end_blocks.length, 1
        pr = @__at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpfile), "tmpfile should be removed."
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    it "[!yvfxq] raises error when dummy file already exists." do
      tmp = "_tmp_4883.txt"
      [true, false].each do |flag|
        begin
          flag ? File.write(tmp, "") : Dir.mkdir(tmp)
          assert_exc(ArgumentError, "dummy_file('#{tmp}'): temporary file already exists.") do
            dummy_file(tmp, "foobar")
          end
        ensure
          File.unlink(tmp) if File.file?(tmp)
          Dir.rmdir(tmp)   if File.directory?(tmp)
        end
      end
    end
    it "[!nvlkq] returns filename." do
      tmpfile = "_tmp_4947.txt"
      begin
        ret = dummy_file(tmpfile, "foobar")
        assert_eq ret, tmpfile
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    it "[!3mg26] generates temporary filename if 1st arg is nil." do
      begin
        tmpfile1 = dummy_file(nil, "foobar")
        tmpfile2 = dummy_file(nil, "foobar")
        assert tmpfile1 =~ /^_tmpfile_\d{6}/, "tempoary filename should be generated."
        assert tmpfile2 =~ /^_tmpfile_\d{6}/, "tempoary filename should be generated."
        assert tmpfile1 != tmpfile2, "tempoary filename should contain random number."
      ensure
        File.unlink(tmpfile1) if File.exist?(tmpfile1)
        File.unlink(tmpfile2) if File.exist?(tmpfile2)
      end
    end
    it "[!ky7nh] can take block argument." do
      tmpfile = "_tmp_9080"
      begin
        ret = dummy_file(tmpfile) do |filename|
          assert_eq filename, tmpfile
          assert File.file?(tmpfile), "tmpfile should be created."
          1234
        end
        assert !File.file?(tmpfile), "tmpfile should be removed."
        assert_eq ret, 1234
        assert_eq @__at_end_blocks, nil
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
  end

  describe '#dummy_dir()' do
    it "[!l34d5] creates dummy directory." do
      tmpdir = "_tmpdir_7903"
      Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      begin
        dummy_dir(tmpdir)
        assert File.exist?(tmpdir), "tmpdir should be created."
        assert_eq @__at_end_blocks.length, 1
        pr = @__at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpdir), "tmpdir should be removed."
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "[!zypj6] raises error when dummy dir already exists." do
      tmp = "_tmpdir_1062"
      [true, false].each do |flag|
        begin
          flag ? Dir.mkdir(tmp) : File.write(tmp, "")
          assert_exc(ArgumentError, "dummy_dir('#{tmp}'): temporary directory already exists.") do
            dummy_dir(tmp)
          end
        ensure
          Dir.rmdir(tmp)   if File.directory?(tmp)
          File.unlink(tmp) if File.file?(tmp)
        end
      end
    end
    it "[!01gt7] removes dummy directory even if it contains other files." do
      tmpdir = "_tmpdir_3869"
      begin
        dummy_dir(tmpdir)
        File.write("#{tmpdir}/foo.txt", "foofoo", encoding: 'utf-8')
        Dir.mkdir("#{tmpdir}/d1")
        Dir.mkdir("#{tmpdir}/d1/d2")
        File.write("#{tmpdir}/d1/d2/bar.txt", "barbar", encoding: 'utf-8')
        assert File.exist?("#{tmpdir}/foo.txt"), "should exists."
        assert File.exist?("#{tmpdir}/d1/d2/bar.txt"), "should exists."
        #
        pr = @__at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpdir), "tmpdir should be removed."
      ensure
        FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "[!jxh30] returns directory name." do
      tmpdir = "_tmpdir_2546"
      begin
        ret = dummy_dir(tmpdir)
        assert_eq ret, tmpdir
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "[!r14uy] generates temporary directory name if 1st arg is nil." do
      begin
        tmpdir1 = dummy_dir(nil)
        tmpdir2 = dummy_dir()
        assert tmpdir1 =~ /^_tmpdir_\d{6}/, "tempoary directory name should be generated."
        assert tmpdir2 =~ /^_tmpdir_\d{6}/, "tempoary directory name should be generated."
        assert tmpdir1 != tmpdir2, "tempoary directory name should contain random number."
      ensure
        Dir.rmdir(tmpdir1) if File.exist?(tmpdir1)
        Dir.rmdir(tmpdir2) if File.exist?(tmpdir2)
      end
    end
    it "[!tfsqo] can take block argument." do
      tmpdir = "_tmp_5799"
      begin
        ret = dummy_dir(tmpdir) do |dirname|
          assert_eq dirname, tmpdir
          assert File.directory?(tmpdir), "tmpdir should be created."
          2345
        end
        assert !File.directory?(tmpdir), "tmpdir should be removed."
        assert_eq ret, 2345
        assert_eq @__at_end_blocks, nil
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
  end

  describe '#dummy_values()' do
    it "[!hgwg2] changes hash value temporarily." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq hashobj[:a], 1000
      assert_eq hashobj['b'], 2000
      assert_eq hashobj[:c], 30
      assert_eq hashobj[:x], 9000
    end
    it "[!jw2kx] recovers hash values." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq hashobj[:a], 1000
      assert_eq hashobj['b'], 2000
      assert_eq hashobj[:c], 30
      assert_eq hashobj[:x], 9000
      assert_eq @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      assert_eq hashobj[:a], 10
      assert_eq hashobj['b'], 20
      assert_eq hashobj[:c], 30
      assert !hashobj.key?(:x), "key :x should not exist."
    end
    it "[!w3r0p] returns keyvals." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      ret = dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq ret, {:a=>1000, 'b'=>2000, :x=>9000}
    end
    it "[!pwq6v] can take block argument." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      ret = dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000) do |kvs|
        assert_eq hashobj[:a], 1000
        assert_eq hashobj['b'], 2000
        assert_eq hashobj[:c], 30
        assert_eq hashobj[:x], 9000
        assert_eq kvs, {:a=>1000, 'b'=>2000, :x=>9000}
        5678
      end
      assert_eq ret, 5678
      assert_eq hashobj[:a], 10
      assert_eq hashobj['b'], 20
      assert_eq hashobj[:c], 30
      assert !hashobj.key?(:x), "key :x should not exist."
      assert_eq @__at_end_blocks, nil
    end
  end

  describe '#dummy_attrs()' do
    it "[!4vd73] changes object attributes temporarily." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      assert_eq obj.id, 999
      assert_eq obj.name, "bob"
    end
    it "[!fi0t3] recovers attribute values." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      assert_eq obj.id, 999
      assert_eq obj.name, "bob"
      #
      assert_eq @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      assert_eq obj.id, 123
      assert_eq obj.name, "alice"
    end
    it "[!27yeh] returns keyvals." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>789, :name=>"charlie")
      assert_eq ret, {:id=>789, :name=>"charlie"}
    end
    it "[!j7tvp] can take block argument." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>888, :name=>"dave") do |kvs|
        assert_eq obj.id, 888
        assert_eq obj.name, "dave"
        assert_eq kvs, {:id=>888, :name=>"dave"}
        4567
      end
      assert_eq ret, 4567
      assert_eq obj.id, 123
      assert_eq obj.name, "alice"
      assert_eq @__at_end_blocks, nil
    end
  end

  describe '#dummy_ivars()' do
    it "[!rnqiv] changes instance variables temporarily." do
      obj = DummyUser.new(123, "alice")
      dummy_ivars(obj, :id=>999, :name=>"bob")
      assert_eq obj.instance_variable_get('@id'), 999
      assert_eq obj.instance_variable_get('@name'), "bob"
    end
    it "[!8oirn] recovers instance variables." do
      obj = DummyUser.new(123, "alice")
      dummy_ivars(obj, :id=>999, :name=>"bob")
      assert_eq obj.instance_variable_get('@id'), 999
      assert_eq obj.instance_variable_get('@name'), "bob"
      #
      assert_eq @__at_end_blocks.length, 1
      pr = @__at_end_blocks.pop()
      pr.call()
      assert_eq obj.instance_variable_get('@id'), 123
      assert_eq obj.instance_variable_get('@name'), "alice"
    end
    it "[!01dc8] returns keyvals." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_ivars(obj, :id=>789, :name=>"charlie")
      assert_eq ret, {:id=>789, :name=>"charlie"}
    end
    it "[!myzk4] can take block argument." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>888, :name=>"dave") do |kvs|
        assert_eq obj.instance_variable_get('@id'), 888
        assert_eq obj.instance_variable_get('@name'), "dave"
        assert_eq kvs, {:id=>888, :name=>"dave"}
        4567
      end
      assert_eq ret, 4567
      assert_eq obj.id, 123
      assert_eq obj.name, "alice"
      assert_eq @__at_end_blocks, nil
    end
  end

  describe '#recorder()' do
    it "[!qwrr8] loads 'benry/recorder' automatically." do
      if defined?(Benry::Recorder)
        $stderr.puts "** skip because 'benry/recorder' already loaded."
      else
        assert !defined? Benry::Recorder, "should not be loaded."
        recorder()
        assert defined? Benry::Recorder, "should be loaded."
      end
    end
    it "[!glfvx] creates Benry::Recorder object." do
      rec = recorder()
      assert rec.is_a?(Benry::Recorder)
      o = rec.fake_object(:foo=>123)
      assert_eq o.foo(), 123
      assert_eq rec[0].name, :foo
      assert_eq rec[0].obj, o
    end
  end

end
