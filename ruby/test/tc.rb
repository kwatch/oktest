# -*- coding: utf-8 -*-

## micro test case class
class TC

  COUNTS = {:ok => 0, :fail => 0, :error => 0}

  def self.report_result()
    ok, fail, error = COUNTS[:ok], COUNTS[:fail], COUNTS[:error]
    COUNTS.keys.each {|k| COUNTS[k] = 0 }
    red = proc {|s| "\033[0;31m#{s}\033[0m" }
    fail_s  = "fail: #{fail}"   ; fail_s  = red.call(fail_s)  if fail > 0
    error_s = "error: #{error}" ; error_s = red.call(error_s) if error > 0
    STDOUT.puts "## total: #{ok+fail+error} (ok: #{ok}, #{fail_s}, #{error_s})"
  end

  def self.describe(target, &b)
    prev, @curr_target = @curr_target, target
    yield
  ensure
    @curr_target = prev
  end

  def self.curr_target()
    @curr_target
  end

  def self.it(spec, &b)
    t = @curr_target
    print "[#{self.name}#{t ? ' > ' : ''}#{t}] #{spec} ... "
    obj = self.new
    obj.setup()
    begin
      obj.instance_eval(&b)
    rescue => ex
      if ex.is_a?(AssertionFailed)
        puts "FAILED!"; COUNTS[:fail]  += 1
      else
        puts "ERROR!" ; COUNTS[:error] += 1
      end
      puts "  #{ex.class.name}: #{ex.message}"
      ex.backtrace.each do |bt|
        puts "    #{bt}" if bt.index(__FILE__) == nil
      end
    else
      puts "ok."; COUNTS[:ok] += 1
    ensure
      obj.teardown()
    end
  end

  def setup
  end

  def teardown
  end

  class AssertionFailed < StandardError
  end

  def assert(cond, msg=nil)
    raise msg unless cond
  end

  def assert_eq(actual, expected)
    return if actual == expected
    multiline_p = actual.is_a?(String) && actual =~ /\n/ \
                && expected.is_a?(String) && expected =~ /\n/
    errmsg = (multiline_p \
              ? "$<actual> == $<expected> : failed.\n" +
                "    $<actual>:   <<END\n#{actual}END\n" +
                "    $<expected>: <<END\n#{expected}END"
              : "$<actual> == $<expected> : failed.\n" +
                "    $<actual>:   #{actual.inspect}\n" +
                "    $<expected>: #{expected.inspect}")
    raise AssertionFailed, errmsg
  end

  def capture(tty: true, &b)
    require 'stringio' unless defined?(StringIO)
    stdout, stderr = $stdout, $stderr
    $stdout = sout = StringIO.new
    $stderr = serr = StringIO.new
    def sout.tty?; true; end if tty
    def sout.tty?; true; end if tty
    yield
    return sout.string, serr.string
  ensure
    $stdout, $stderr = stdout, stderr
  end

end


at_exit { TC.report_result() }