###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

module Oktest

  @DIFF = ENV['DIFF'] || File.file?('/usr/bin/diff')

  def self.DIFF
    @DIFF
  end

  def self.DIFF=(command)
    @DIFF = command
  end

  def self.diff(actual, expected)
    ## actual and expected should be different
    return nil if actual == expected
    ## both actual and expected should be String
    return nil unless actual.is_a?(String) && expected.is_a?(String)
    ## either actual or expected should have enough length
    return nil if actual.length < 10 && expected.length < 10
    ## diff command
    command = Oktest.DIFF
    return nil unless command
    command = 'diff -u' if command == true
    ## diff
    require 'tempfile' unless defined?(Tempfile)
    output = nil
    #Tempfile.open('actual') do |af|    # af.path file is not removed. why?
    #  af.write(actual); af.flush()
    #  Tempfile.open('expected') do |ef|
    #    ef.write(expected); ef.flush()
    #    #output = `#{command} #{ef.path} #{af.path}`
    #    output = IO.popen(cmd="#{command} #{ef.path} #{af.path}") {|io| io.read }
    #  end
    #end
    af = ef = nil
    begin
      af = Tempfile.open('actual')   ; af.write(actual)   ; af.flush
      ef = Tempfile.open('expected') ; ef.write(expected) ; ef.flush
      #output = `#{command} #{ef.path} #{af.path}`
      output = IO.popen("#{command} #{ef.path} #{af.path}") {|io| io.read() }
    ensure
      af.close if ef
      ef.close if ef
    end
    return output.sub(/\A.*?\n.*?\n/, "--- expected\n+++ actual\n")
  end


  class AssertionFailed < Exception
    attr_accessor :diff
  end


  class AssertionObject

    attr_reader :actual, :negative

    def initialize(this, actual, negative=false)
      @this = this
      @actual = actual
      @negative = negative
    end

    def ==(expected)
      begin
        do_assert(@actual == expected, expected, '==', '!=')
      rescue AssertionFailed => ex
        ex.diff = Oktest.diff(@actual, expected) if @actual != expected
        raise ex
      end
    end

#    def !=(expected)
#      do_assert(@actual == expected, expected, '!=', '==')
#    end

    def >(expected)
      do_assert(@actual > expected, expected, '>', '<=')
    end

    def <(expected)
      do_assert(@actual < expected, expected, '<', '>=')
    end

    def >=(expected)
      do_assert(@actual >= expected, expected, '>=', '<')
    end

    def <=(expected)
      do_assert(@actual <= expected, expected, '<=', '>')
    end

    def ===(expected)
      do_assert(@actual === expected, expected, '===', '!==')
    end

    def =~(expected)
      do_assert(@actual =~ expected, expected, '=~', '!~')
    end

    def nearly_equal(expected, delta)
      flag = expected - delta <= @actual && @actual <= expected + delta
      check2(flag) { "(#{(expected - delta).inspect} <= #{@actual.inspect} <= #{(expected + delta).inspect})" }
    end

    def file?
      check2(File.file?(@actual)) { "File.file?(#{@actual.inspect})" }
    end

    def directory?
      check2(File.directory?(@actual)) { "File.directory?(#{@actual.inspect})" }
    end

    def exist?
      check2(File.exist?(@actual)) { "File.exist?(#{@actual.inspect})" }
    end

    def equal?(expected)
      check2(@actual.equal?(expected)) { "#{@actual.inspect}.equal?(#{expected.inspect})" }
    end

    def in?(expected)
      check2(expected.include?(@actual)) { "#{expected.inspect}.include?(#{@actual.inspect})" }
    end

    def include?(expected)
      check2(@actual.include?(expected)) { "#{@actual.inspect}.include?(#{expected.inspect})" }
    end

    def empty?
      check2(@actual.empty?) { "#{@actual.inspect}.empty?" }
    end

    def raise?(exception_class, message=nil)
      if @negative
        _should_not_raise(exception_class)
      else
        _should_raise(exception_class, message)
      end
    end

    private

    def _should_raise(exception_class, message)
      not_raised = false
      begin
        @actual.call
        not_raised = true
      rescue Exception => ex
        @actual.instance_variable_set('@exception', ex)
        def @actual.exception; @exception; end
        ex.class <= exception_class  or
          raise new_assertion_failed("#{exception_class.name} expected but #{ex.class.name} raised.", 2)
        ! message || ex.message == message  or
          raise new_assertion_failed("#{ex.message.inspect} == #{message.inspect}: failed.", 2)
      end
      raise new_assertion_failed("#{exception_class.name} expected but not raised.", 2) if not_raised
    end

    def _should_not_raise(exception_class=Exception)
      begin
        @actual.call
      rescue Exception => ex
        @actual.instance_variable_set('@exception', ex)
        def @actual.exception; @exception; end
        if ex.class <= exception_class
          raise new_assertion_failed("unexpected #{ex.class.name} raised.", 2)
        end
      end
    end

    def do_assert(flag, expected, op, negative_op)
      flag, msg = check(flag, expected, op, negative_op)
      return true if flag
      raise new_assertion_failed(msg)
    end

    def new_assertion_failed(msg, depth=2)
      ex = AssertionFailed.new(msg)
      ex.set_backtrace(caller(depth+1))    # manipulate backtrace
      return ex
    end

    def check(flag, expected, op, negative_op)
      if @negative
        flag = ! flag
        op = negative_op
      end
      msg = flag ? nil : failed_message(expected, op)
      return flag, msg
    end

    def failed_message(expected, op)
      "#{@actual.inspect} #{op} #{expected.inspect}: failed."
    end

#--
#    def check2(flag, expr)
#      if @negative
#        flag = ! flag
#        expr = "! #{expr}"
#      end
#      return true if flag
#      raise new_assertion_failed("#{expr}: failed.")
#    end
#++
    def check2(flag)
      flag = ! flag if @negative
      return true if flag
      expr = yield
      expr = "! #{expr}" if @negative
      raise new_assertion_failed("#{expr}: failed.")
    end

  end


  module TestCaseUtil

    ## marker method to represent pre-condition
    def pre_cond; yield; end

    ## marker method to represent post-condition
    def post_cond; yield; end

    ## marker method to describe test case
    def case_for(desc); yield; end

    ## marker method to describe test case
    def case_if(desc); yield; end

  end


  module TestCase
    include TestCaseUtil

    def ok(actual=nil)
      actual = yield if block_given?       # experimental
      return Oktest::AssertionObject.new(self, actual, false)
    end

    def not_ok(actual=nil)
      actual = yield if block_given?       # experimental
      return Oktest::AssertionObject.new(self, actual, true)
    end

    def self.included(klass)

      def klass.method_added(name)
        dict = (@_test_method_names_dict ||= {})
        name = name.to_s
        if name =~ /\Atest_?/
          ## if test method name is duplicated, raise error
          dict[name].nil?  or
            raise NameError.new("#{self.name}##{name}(): already defined (please change test method name).")
          dict[name] = dict.size()
          ## if ENV['TEST'] is set, remove unmatched method
          if ENV['TEST']
            remove_method(name) unless name.sub(/\Atest_?/, '').index(ENV['TEST'])
          end
        end
      end

      def klass.test(desc, &block)
        @_test_count ||= 0
        @_test_count += 1
        method_name = "test_%03d_%s" % [@_test_count, desc.to_s.gsub(/[^\w]/, '_')]
        define_method(method_name, block)
      end

    end

  end


  class Reporter

    def before_all(klass)
    end

    def after_all(klass)
    end

    def before(obj)
    end

    def after(obj)
    end

    def print_ok(obj)
    end

    def print_failed(obj, ex)
    end

    def print_error(obj, ex)
    end

  end


  class BaseReporter < Reporter

    def initialize(out=nil)
      @out = out || $stderr
      @_flush = @out.respond_to?(:flush)
    end

    private

    def _test_ident(obj)
      return obj.instance_variable_get('@_test_method')
    end

    def write(str)
      @out << str
      @out.flush if @_flush
    end

    def print_backtrace(ex, out=@out)
      ex.backtrace.each do |str|
        out << "    #{str}\n"
        if str =~ /\A(.*):(\d+):in `(.*?)'/
          filepath, linenum, method = $1, $2.to_i, $3
          #break if method =~ /\Atest_?/
          line = get_line(filepath, linenum)
          out << "      #{line.strip}\n" if line
          break if method =~ /\Atest_?/
        end
      end
    end

    def get_line(filepath, linenum)
      return nil unless File.file?(filepath)
      linenum = linenum.to_i
      line = File.open(filepath) do |f|
        i = 0
        f.find { (i += 1) == linenum }
      end
      return line
    end

  end


  class SimpleReporter < BaseReporter

    def before_all(klass)
      write("### %s\n" % klass.name)
      @buf = ""
    end

    def after_all(klass)
      write("\n")
      @out << @buf.to_s
      @buf = nil
    end

    def before(obj)
    end

    def after(obj)
    end

    def print_ok(obj)
      write(".")
    end

    def print_failed(obj, ex)
      write("f")
      @buf << "Failed: #{_test_ident(obj)}()\n"
      @buf << "    #{ex.message}\n"
      print_backtrace(ex, @buf)
      #assert ex.is_a?(AssertionFailed)
      @buf << ex.diff if ex.diff
    end

    def print_error(obj, ex)
      write("E")
      @buf << "ERROR: #{_test_ident(obj)}()\n"
      @buf << "    #{ex.class.name}: #{ex.message}\n"
      print_backtrace(ex, @buf)
    end

  end


  class VerboseReporter < BaseReporter

    def before_all(klass)
      write("### %s\n" % klass.name)
    end

    def after_all(klass)
      write("\n")
    end

    def before(obj)
      write("- #{_test_ident(obj)} ... ")
    end

    def after(obj)
    end

    def print_ok(obj)
      write("ok\n")
    end

    def print_failed(obj, ex)
      write("FAILED\n")
      write("    #{ex.message}\n")
      print_backtrace(ex, @out)
      #assert ex.is_a?(AssertionFailed)
      write(ex.diff) if ex.diff
    end

    def print_error(obj, ex)
      write("ERROR\n")
      write("  #{ex.class.name}: #{ex.message}\n")
      print_backtrace(ex, @out)
    end

  end


  REPORTER = SimpleReporter


  class Runner

    def initialize(reporter=nil)
      @reporter = reporter || REPORTER.new
    end

    def test_method_names_from(klass)
      test_method_names = klass.instance_methods(true).collect {|sym| sym.to_s }.grep(/\Atest/).sort()
      dict = klass.instance_variable_get('@_test_method_names_dict')
      if dict
        dict = dict.dup()   # key: test method name (String), value: index (Integer)
        i = 0
        test_method_names.select {|name| ! dict.key?(name) }.reverse.each {|name| dict[name] = (i -= 1) }
        test_method_names = dict.sort_by {|k, v| v }.collect {|k, v| k }
      end
      return test_method_names
    end

    def run(klass)
      reporter = @reporter
      ## gather test methods
      test_method_names = test_method_names_from(klass)
      ## filer by $TEST environment variable
      pattern = ENV['TEST']
      test_method_names.delete_if {|x| x.index(pattern).nil? } if pattern
      ## sort by linenumber
      # nothing
      ## invoke before_all()
      reporter.before_all(klass)
      klass.before_all() if klass.respond_to?(:before_all)
      ## invoke test methods
      count = 0
      flag_before   = klass.method_defined?(:before)
      flag_setup    = klass.method_defined?(:setup)
      flag_after    = klass.method_defined?(:after)
      flag_teardown = klass.method_defined?(:teardown)
      test_method_names.each do |method_name|
        ## create instance object for each test
        begin
          obj = klass.new
        rescue ArgumentError
          obj = klass.new(method_name)
        end
        obj.instance_variable_set('@_name', method_name.sub(/\Atest_?/, ''))
        obj.instance_variable_set('@_test_method', method_name)
        ## invoke before() or setup()
        reporter.before(obj)
        flag_before ? obj.before() : flag_setup ? obj.setup() : nil
        ## invoke test method
        begin
          obj.__send__(method_name)
          reporter.print_ok(obj)
        rescue Oktest::AssertionFailed => ex
          count += 1
          reporter.print_failed(obj, ex)
        rescue Exception => ex
          count += 1
          reporter.print_error(obj, ex)
        ensure
          ## invoke after() or teardown()
          flag_after ? obj.after() : flag_teardown ? obj.teardown() : nil
        end
      end
      ## invoke after_all()
      klass.after_all() if klass.respond_to?(:after_all)
      reporter.after_all(klass)
      ##
      return count
    end
  end


  def self.run(*classes)
    opts = classes.last.is_a?(Hash) ? classes.pop() : {}
    reporter_class = opts[:verbose] ? VerboseReporter : REPORTER
    reporter = reporter_class.new(opts[:out])
    runner = Runner.new(reporter)
    classes.each {|cls| runner.run(cls) }
  end


end
