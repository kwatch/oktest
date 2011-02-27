###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest';  Oktest.run_at_exit = false


class OktestTestCaseTest < Test::Unit::TestCase

  def spec(desc); yield; end

  ##
  ## duplicated method should be reported
  ##

  def test_method_added
    spec "duplicated method should be reported" do
      ex = assert_raise(NameError) do
        eval <<-END, binding(), __FILE__, __LINE__+1
        class HogeTest1
          include Oktest::TestCase
          def test1; ok(1+1)==2; end
          def test1; ok(1+1)==2; end    # duplicated method
        end
        END
      end
      expected = "OktestTestCaseTest::HogeTest1#test1(): already defined (please change test method name)."
      assert_equal expected, ex.message
    end
  end


  ##
  ## self.test() defines test method
  ##

  class HogeTest2
    include Oktest::TestCase
    test "1+1 should be 2" do
      ok(1+1) == 2
    end
    test "1-1 should be 0" do
      ok(1-1) == 0
    end
  end

  def test_test
    spec "test() defines test method" do
      test_method_names = HogeTest2.instance_methods().collect {|sym| sym.to_s }.grep(/\Atest_/).sort
      expected = ['test_001_1_1_should_be_2', 'test_002_1_1_should_be_0']
      assert_equal expected, test_method_names
    end
  end


  ##
  ## pre_cond(), post_cond(), case_for(), case_if()
  ##

  class HogeTest3
    include Oktest::TestCase
    def call_pre_cond
      done = false
      pre_cond { done = true }
      return done
    end
    def call_post_cond
      done = false
      post_cond { done = true }
      return done
    end
    def call_target
      done = false
      target("desc") { done = true }
      return done
    end
    def call_spec
      done = false
      spec("desc") { done = true }
      return done
    end
  end

  def test_pre_cond
    spec "just invokes block" do
      assert_equal true, HogeTest3.new.call_pre_cond
    end
  end

  def test_post_cond
    spec "just invokes block" do
      assert_equal true, HogeTest3.new.call_post_cond
    end
  end

  def test_target
    spec "just invokes block" do
      assert_equal true, HogeTest3.new.call_target
    end
  end

  def test_spec
    spec "just invokes block" do
      assert_equal true, HogeTest3.new.call_spec
    end
  end


  ##
  ## capture_io()
  ##

  def test_capture_io
    extend Oktest::TestCase
    spec "captures $stdout and $stderr" do
      sout, serr = capture_io() do
        $stdout.write("Suzumiya")
        $stderr.write("Haruhi")
      end
      assert_equal "Suzumiya", sout
      assert_equal "Haruhi", serr
    end
    spec "takes string as $stdin" do
      sout, serr = capture_io("Haruhi Suzumiya") do
        input = $stdin.read()
        $stdout.write("input=#{input.inspect}")
      end
      assert_equal 'input="Haruhi Suzumiya"', sout
    end
    spec "restore $stdin, $stdout, and $stderr after block yielded" do
      stdin, stdout, stderr = $stdin, $stdout, $stderr
      sout, serr = capture_io("sos") do
        assert_not_same stdin,  $stdin
        assert_not_same stdout, $stdout
        assert_not_same stderr, $stderr
      end
      assert_same stdin,  $stdin
      assert_same stdout, $stdout
      assert_same stderr, $stderr
    end
  end


  ##
  ## dummy_file(), dummy_dir()
  ##
  def test_dummy_file()
    extend Oktest::TestCase
    spec "dummy file should be remove after block yielded" do
      assert ! File.exist?('A.txt')
      dummy_file('A.txt'=>'AAA') do
        assert File.exist?('A.txt')
        assert_equal 'AAA', File.read('A.txt')
      end
      assert ! File.exist?('A.txt')
    end
    spec "directory should be created in ahead" do
      ex = assert_raise(Errno::ENOENT) do
        dummy_file('xxx/A.txt'=>'AAA') do
          nil
        end
      end
      assert_equal "No such file or directory - xxx/A.txt", ex.message
    end
  end

  def test_dummy_dir()
    extend Oktest::TestCase
    spec "dummy file should be remove after block yielded" do
      begin
        assert ! File.exist?('xxx.d')
        assert ! File.exist?('yyy.d')
        dummy_dir('xxx.d', 'yyy.d/zzz') do
          assert File.directory?('xxx.d')
          assert File.directory?('yyy.d')
          assert File.directory?('yyy.d/zzz')
          File.open('xxx.d/A.txt', 'w') {|f| f.write("dummy") }
          File.open('yyy.d/zzz/B.txt', 'w') {|f| f.write("dummy") }
        end
        assert ! File.exist?('xxx.d')
        assert ! File.exist?('yyy.d/zzz')
        assert   File.exist?('yyy.d')
      ensure
        require 'fileutils'
        FileUtils.rm_rf(['xxx.d', 'yyy.d'])
      end
    end
    spec "directory should be created in ahead" do
      ex = assert_raise(Errno::ENOENT) do
        dummy_file('xxx/A.txt'=>'AAA') do
          nil
        end
      end
      assert_equal "No such file or directory - xxx/A.txt", ex.message
    end
  end



  ##
  ## 'include Oktest::TestCase' sets Oktest::TestCase._subclasses automatically
  ##
  def test__subclasses
    spec "Oktest::TestCase._subclasses() contains class objects which include Oktest::TestCase module" do
      classes = Oktest::TestCase._subclasses()
      assert classes.include?(HogeTest2)
      assert classes.include?(HogeTest3)
    end
  end


  class Hello
    def hello(name); return "Hello #{name}!"; end
    def greeting(name, lang=nil)
      if lang.nil? || lang == "en"
        hello(name).sub(/Hello/, 'Hi')
      end
    end
  end


end
