# -*- coding: utf-8 -*-
# frozen_string_literal: true


module NanoTest
  module_function

  def test_target(target, &b)
    yield
  end

  def test_subject(subject, &b)
    yield
    print "."
    $microtest_count += 1
  end

  $microtest_count = 0

  class TestFailed < StandardError
  end

  def test_ok(result, msg: nil)
    unless result
      msg ||= "Test failed."
      raise TestFailed, msg
    end
  end

  def test_eq(actual, expected)
    unless actual == expected
      s1 = "  $<expected>: #{expected.inspect}"
      s2 = "  $<actual>:   #{actual.inspect}"
      raise TestFailed, "$<actual> == $<expected> : failed.\n#{s1}\n#{s2}"
    end
  end

  def test_exception(exception_class, &b)
    begin
      yield
    rescue exception_class => exc
      return exc
    else
      raise TestFailed, "Expected #{exception_class.name} to be raised, but not."
    end
  end

  def capture_output(stdin="", tty: false, &b)
    require 'stringio' unless defined?(StringIO)
    bkup = [$stdin, $stdout, $stderr]
    $stdin  = StringIO.new(stdin)
    $stdout = StringIO.new
    $stderr = StringIO.new
    if tty
      def $stdin.tty? ; true; end
      def $stdout.tty?; true; end
      def $stderr.tty?; true; end
    end
    yield
    stdout_output = $stdout.string
    stderr_output = $stderr.string
    return stdout_output, stderr_output
  ensure
    $stdin, $stdout, $stderr = bkup
  end

end


at_exit {
  if $microtest_count > 0
    puts "\n"
    puts "(#{$microtest_count} tests)"
  end
}


if __FILE__ == $0

  self.extend NanoTest

  def do_test(desc, &b)
    yield desc
  end

  ## test_target()
  do_test "test_target() yields block." do |desc|
    called = false
    test_target 'example' do
      called = true
    end
    called == true  or fail "Failed: #{desc}"
  end

  ## test_subject()
  do_test "test_subject() yields block." do |desc|
    called = false
    test_subject 'example' do
      called = true
    end
    called == true  or fail "Failed: #{desc}"
  end

  ## test_ok()
  do_test "test_ok() raises nothing if arg is truthy." do |desc|
    test_ok (1+1) == 2
  end
  do_test "test_ok() raises TestFailed if arg is falty." do |desc|
    begin
      test_ok (1+1) == 3
    rescue NanoTest::TestFailed => exc
      expected = "Test failed."
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_ok() accepts a message string." do |desc|
    msg = "should be equal to 2"
    begin
      test_ok (1+1) == 3, msg: msg
    rescue NanoTest::TestFailed => exc
      exc.message == msg  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end

  ## test_eq()
  do_test "test_eq() raises nothing if args are equal." do |desc|
    test_eq "ABC", "ABC"
  end
  do_test "test_eq() raises TestFailed if args are not equal." do |desc|
    begin
      test_eq "ABC", "abc"
    rescue NanoTest::TestFailed => exc
      expected = "$<actual> == $<expected> : failed.\n"\
                 "  $<expected>: \"abc\"\n"\
                 "  $<actual>:   \"ABC\""
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end

  ## test_exception()
  do_test "test_exception() raises nothing if expected exception raised in block." do
    test_exception ZeroDivisionError do
      1 / 0
    end
  end
  do_test "test_exception() raises TestFailed if expected exception not raised in block." do
    begin
      test_exception ZeroDivisionError do
        1.0 / 0.0
      end
    rescue NanoTest::TestFailed => exc
      expected = "Expected ZeroDivisionError to be raised, but not."
      exc.message == expected or fail "Failed: #{desc}"
    end
  end

  ## capture_output()
  do_test "capture_output() captures stdout and stderro." do |desc|
    sout, serr = capture_output() do
      print "ABC"
      $stderr.print "DEF"
    end
    sout == "ABC"  or fail "Failed (sout): #{desc}"
    serr == "DEF"  or fail "Failed (serr): #{desc}"
  end
  do_test "capture_output() accepts stdin data." do |desc|
    data = nil
    capture_output("abc\n") do
      data = $stdin.read()
    end
    data == "abc\n"  or fail "Failed: #{desc}"
  end
  do_test "capture_output() restores original stdin, stdout and stderr." do |desc|
    io = [$stdin, $stdout, $stderr]
    capture_output() do
      $stdin  != io[0]  or fail "Failed (stdin): #{desc}"
      $stdout != io[1]  or fail "Failed (stdout): #{desc}"
      $stderr != io[2]  or fail "Failed (stderr): #{desc}"
    end
    $stdin  == io[0]  or fail "Failed (stdin): #{desc}"
    $stdout == io[1]  or fail "Failed (stdout): #{desc}"
    $stderr == io[2]  or fail "Failed (stderr): #{desc}"
  end
  do_test "capture_output() makes io objects to pseudo tty." do |desc|
    capture_output(tty: true) do
      $stdin.tty?  == true   or fail "Failed (stdin): #{desc}"
      $stdout.tty? == true   or fail "Failed (stdout): #{desc}"
      $stderr.tty? == true   or fail "Failed (stderr): #{desc}"
    end
    capture_output(tty: false) do
      $stdin.tty?  == false  or fail "Failed (stdin): #{desc}"
      $stdout.tty? == false  or fail "Failed (stdout): #{desc}"
      $stderr.tty? == false  or fail "Failed (stderr): #{desc}"
    end
    capture_output() do
      $stdin.tty?  == false  or fail "Failed (stdin): #{desc}"
      $stdout.tty? == false  or fail "Failed (stdout): #{desc}"
      $stderr.tty? == false  or fail "Failed (stderr): #{desc}"
    end
  end

  $microtest_count = 0
  puts ""

end
