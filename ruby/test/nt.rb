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
    $nantotest_subject_count += 1
  end

  $nantotest_subject_count = 0

  class TestFailed < StandardError
  end

  def test_ok?(result, msg: nil)
    return true if result
    msg ||= "Test failed."
    raise TestFailed, msg
  end

  def test_eq?(actual, expected, msg: nil)
    return true if actual == expected
    msg ||= "<ACTUAL> == <EXPECTED> : failed."
    #s1 = "    <ACTUAL>:   #{actual.inspect}"
    #s2 = "    <EXPECTED>: #{expected.inspect}"
    require 'pp' unless defined?(PP)
    s1 = "    <ACTUAL>:   #{PP.pp(actual, String.new).chomp}"
    s2 = "    <EXPECTED>: #{PP.pp(expected, String.new).chomp}"
    raise TestFailed, "#{msg}\n#{s1}\n#{s2}"
  end

  def test_match?(actual_str, expected_rexp, msg: nil)
    return true if actual_str =~ expected_rexp
    msg ||= "<ACTUAL> =~ <EXPECTED> : failed."
    require 'pp' unless defined?(PP)
    s1 = "    <ACTUAL>:   #{PP.pp(actual_str, String.new).chomp}"
    s2 = "    <EXPECTED>: #{PP.pp(expected_rexp, String.new).chomp}"
    raise TestFailed, "#{msg}\n#{s1}\n#{s2}"
  end

  def test_exception?(exception_class, &b)
    begin
      yield
    rescue exception_class => exc
      return exc
    else
      raise TestFailed, "Expected #{exception_class.name} to be raised, but not."
    end
  end

  def capture_output!(stdin="", tty: false, &b)
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
  if $nantotest_subject_count > 0
    puts "\n"
    puts "(#{$nantotest_subject_count} tests)"
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

  ## test_ok?()
  do_test "test_ok?() raises nothing if arg is truthy." do |desc|
    test_ok? (1+1) == 2
  end
  do_test "test_ok?() raises TestFailed if arg is falty." do |desc|
    begin
      test_ok? (1+1) == 3
    rescue NanoTest::TestFailed => exc
      expected = "Test failed."
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_ok?() accepts a message string." do |desc|
    msg = "should be equal to 2"
    begin
      test_ok? (1+1) == 3, msg: msg
    rescue NanoTest::TestFailed => exc
      exc.message == msg  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end

  ## test_eq?()
  do_test "test_eq?() raises nothing if args are equal." do |desc|
    test_eq? "ABC", "ABC"
  end
  do_test "test_eq?() raises TestFailed if args are not equal." do |desc|
    begin
      test_eq? "ABC", "abc"
    rescue NanoTest::TestFailed => exc
      expected = "<ACTUAL> == <EXPECTED> : failed.\n"\
                 "    <ACTUAL>:   \"ABC\"\n"\
                 "    <EXPECTED>: \"abc\""
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_eq?() reports actual and expected value in pretty print format." do |desc|
    begin
      actual1 = {
        name: "Alice", email: "alice@gmail.com", gender: "F",
        department: "Sales & Marketing",
      }
      expected1 = {
        name: "Alice", email: "alice@gmail.org", gender: "F",
        department: "Sales & Marketing",
      }
      test_eq? actual1, expected1
    rescue NanoTest::TestFailed => exc
      expected = <<'END'
<ACTUAL> == <EXPECTED> : failed.
    <ACTUAL>:   {:name=>"Alice",
 :email=>"alice@gmail.com",
 :gender=>"F",
 :department=>"Sales & Marketing"}
    <EXPECTED>: {:name=>"Alice",
 :email=>"alice@gmail.org",
 :gender=>"F",
 :department=>"Sales & Marketing"}
END
      expected = expected.chomp
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_eq?() accepts 'msg:' kwarg." do
    begin
      test_eq? "ABC", "abc", msg: "NOT EQUAL"
    rescue NanoTest::TestFailed => exc
      expected = "NOT EQUAL\n"\
                 "    <ACTUAL>:   \"ABC\"\n"\
                 "    <EXPECTED>: \"abc\""
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end

  ## test_match?()
  do_test "test_match?() raises nothing if str matched to regexp." do |desc|
    test_match? "123", /^\d+$/
  end
  do_test "test_match?() raises TestFailed if str not matched to regexp." do |desc|
    begin
      test_match? "ABC", /^\d+$/
    rescue NanoTest::TestFailed => exc
      expected = "<ACTUAL> =~ <EXPECTED> : failed.\n"\
                 "    <ACTUAL>:   \"ABC\"\n"\
                 "    <EXPECTED>: /^\\d+$/"
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_match?() reports str and regexp values in pretty print format." do |desc|
    begin
      test_match? "ABC\nDEF\nGHI\n", /^\d+$/
    rescue NanoTest::TestFailed => exc
      expected = <<'END'
<ACTUAL> =~ <EXPECTED> : failed.
    <ACTUAL>:   "ABC\n" + "DEF\n" + "GHI\n"
    <EXPECTED>: /^\d+$/
END
      expected = expected.chomp
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end
  do_test "test_match?() accepts 'msg:' kwarg." do
    begin
      test_match? "ABC", /^\d+$/, msg: "NOT MATCHED"
    rescue NanoTest::TestFailed => exc
      expected = "NOT MATCHED\n"\
                 "    <ACTUAL>:   \"ABC\"\n"\
                 "    <EXPECTED>: /^\\d+$/"
      exc.message == expected  or fail "Failed: #{desc}"
    else
      fail "TestFailed should be raised but not: #{desc}"
    end
  end

  ## test_exception?()
  do_test "test_exception?() raises nothing if expected exception raised in block." do
    test_exception? ZeroDivisionError do
      1 / 0
    end
  end
  do_test "test_exception?() raises TestFailed if expected exception not raised in block." do
    begin
      test_exception? ZeroDivisionError do
        1.0 / 0.0
      end
    rescue NanoTest::TestFailed => exc
      expected = "Expected ZeroDivisionError to be raised, but not."
      exc.message == expected or fail "Failed: #{desc}"
    end
  end

  ## capture_output!()
  do_test "capture_output!() captures stdout and stderro." do |desc|
    sout, serr = capture_output!() do
      print "ABC"
      $stderr.print "DEF"
    end
    sout == "ABC"  or fail "Failed (sout): #{desc}"
    serr == "DEF"  or fail "Failed (serr): #{desc}"
  end
  do_test "capture_output!() accepts stdin data." do |desc|
    data = nil
    capture_output!("abc\n") do
      data = $stdin.read()
    end
    data == "abc\n"  or fail "Failed: #{desc}"
  end
  do_test "capture_output!() restores original stdin, stdout and stderr." do |desc|
    io = [$stdin, $stdout, $stderr]
    capture_output!() do
      $stdin  != io[0]  or fail "Failed (stdin): #{desc}"
      $stdout != io[1]  or fail "Failed (stdout): #{desc}"
      $stderr != io[2]  or fail "Failed (stderr): #{desc}"
    end
    $stdin  == io[0]  or fail "Failed (stdin): #{desc}"
    $stdout == io[1]  or fail "Failed (stdout): #{desc}"
    $stderr == io[2]  or fail "Failed (stderr): #{desc}"
  end
  do_test "capture_output!() makes io objects to pseudo tty." do |desc|
    capture_output!(tty: true) do
      $stdin.tty?  == true   or fail "Failed (stdin): #{desc}"
      $stdout.tty? == true   or fail "Failed (stdout): #{desc}"
      $stderr.tty? == true   or fail "Failed (stderr): #{desc}"
    end
    capture_output!(tty: false) do
      $stdin.tty?  == false  or fail "Failed (stdin): #{desc}"
      $stdout.tty? == false  or fail "Failed (stdout): #{desc}"
      $stderr.tty? == false  or fail "Failed (stderr): #{desc}"
    end
    capture_output!() do
      $stdin.tty?  == false  or fail "Failed (stdin): #{desc}"
      $stdout.tty? == false  or fail "Failed (stdout): #{desc}"
      $stderr.tty? == false  or fail "Failed (stderr): #{desc}"
    end
  end

  $nantotest_subject_count = 0
  puts ""

end
