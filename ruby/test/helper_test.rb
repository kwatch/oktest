###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


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

end
