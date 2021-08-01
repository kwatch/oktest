###
### $Release: $
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

  describe '#capture_sio()' do
    it "captures $stdio and $stderr" do
      sout, serr = capture_sio() do
        puts "fooo"
        $stderr.puts "baaa"
      end
      assert_eq sout, "fooo\n"
      assert_eq serr, "baaa\n"
    end
    it "takes $stdin data." do
      data = nil
      sout, serr = capture_sio("blabla") do
        data = $stdin.read()
      end
      data = "blabla"
    end
    it "recovers stdio even when exception raised." do
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
    it "can simulate tty." do
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
    it "creates dummy file." do
      tmpfile = "_tmp_3511.txt"
      File.unlink(tmpfile) if File.exist?(tmpfile)
      begin
        dummy_file(tmpfile, "foobar")
        assert File.exist?(tmpfile), "tmpfile should be created."
        assert_eq @_at_end_blocks.length, 1
        pr = @_at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpfile), "tmpfile should be removed."
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    it "returns filename." do
      tmpfile = "_tmp_4947.txt"
      begin
        ret = dummy_file(tmpfile, "foobar")
        assert_eq ret, tmpfile
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
    it "generates temporary filename if 1st arg is nil." do
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
    it "can take block argument." do
      tmpfile = "_tmp_9080"
      begin
        ret = dummy_file(tmpfile) do |filename|
          assert_eq filename, tmpfile
          assert File.file?(tmpfile), "tmpfile should be created."
          1234
        end
        assert !File.file?(tmpfile), "tmpfile should be removed."
        assert_eq ret, 1234
      ensure
        File.unlink(tmpfile) if File.exist?(tmpfile)
      end
    end
  end

  describe '#dummy_dir()' do
    it "creates dummy directory." do
      tmpdir = "_tmpdir_7903"
      Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      begin
        dummy_dir(tmpdir)
        assert File.exist?(tmpdir), "tmpdir should be created."
        assert_eq @_at_end_blocks.length, 1
        pr = @_at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpdir), "tmpdir should be removed."
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "removes dummy directory even if it contains other files." do
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
        pr = @_at_end_blocks.pop()
        pr.call()
        assert !File.exist?(tmpdir), "tmpdir should be removed."
      ensure
        FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "returns directory name." do
      tmpdir = "_tmpdir_2546"
      begin
        ret = dummy_dir(tmpdir)
        assert_eq ret, tmpdir
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
    it "generates temporary directory name if 1st arg is nil." do
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
    it "can take block argument." do
      tmpdir = "_tmp_5799"
      begin
        ret = dummy_dir(tmpdir) do |dirname|
          assert_eq dirname, tmpdir
          assert File.directory?(tmpdir), "tmpdir should be created."
          2345
        end
        assert !File.directory?(tmpdir), "tmpdir should be removed."
        assert_eq ret, 2345
      ensure
        Dir.rmdir(tmpdir) if File.exist?(tmpdir)
      end
    end
  end

  describe '#dummy_values()' do
    it "changes hash value temporarily." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq hashobj[:a], 1000
      assert_eq hashobj['b'], 2000
      assert_eq hashobj[:c], 30
      assert_eq hashobj[:x], 9000
    end
    it "recovers hash values." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq hashobj[:a], 1000
      assert_eq hashobj['b'], 2000
      assert_eq hashobj[:c], 30
      assert_eq hashobj[:x], 9000
      assert_eq @_at_end_blocks.length, 1
      pr = @_at_end_blocks.pop()
      pr.call()
      assert_eq hashobj[:a], 10
      assert_eq hashobj['b'], 20
      assert_eq hashobj[:c], 30
      assert !hashobj.key?(:x), "key :x should not exist."
    end
    it "returns keyvals." do
      hashobj = {:a=>10, 'b'=>20, :c=>30}
      ret = dummy_values(hashobj, :a=>1000, 'b'=>2000, :x=>9000)
      assert_eq ret, {:a=>1000, 'b'=>2000, :x=>9000}
    end
    it "can take block argument." do
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
      assert_eq @_at_end_blocks, nil
    end
  end

  describe '#dummy_attrs()' do
    it "changes object attributes temporarily." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      assert_eq obj.id, 999
      assert_eq obj.name, "bob"
    end
    it "recovers attribute values." do
      obj = DummyUser.new(123, "alice")
      dummy_attrs(obj, :id=>999, :name=>"bob")
      assert_eq obj.id, 999
      assert_eq obj.name, "bob"
      #
      assert_eq @_at_end_blocks.length, 1
      pr = @_at_end_blocks.pop()
      pr.call()
      assert_eq obj.id, 123
      assert_eq obj.name, "alice"
    end
    it "returns keyvals." do
      obj = DummyUser.new(123, "alice")
      ret = dummy_attrs(obj, :id=>789, :name=>"charlie")
      assert_eq ret, {:id=>789, :name=>"charlie"}
    end
    it "can take block argument." do
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
      assert_eq @_at_end_blocks, nil
    end
  end

end
