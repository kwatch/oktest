# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


module Oktest


  VERSION = '$Release: 0.0.0 $'.split()[1]


  class OktestError < StandardError
  end


  class AssertionFailed < StandardError
  end

  class SkipException < StandardError
  end

  class TodoException < StandardError
  end

  #FAIL_EXCEPTION = (defined?(MiniTest)   ? MiniTest::Assertion :
  #                  defined?(Test::Unit) ? Test::Unit::AssertionFailedError : AssertionFailed)
  FAIL_EXCEPTION = AssertionFailed
  SKIP_EXCEPTION = SkipException
  TODO_EXCEPTION = TodoException


  class AssertionObject

    self.instance_methods.grep(/\?\z/).each do |k|
      undef_method k unless k.to_s == 'equal?' || k.to_s =~ /^assert/
    end

    NOT_YET = {}

    def initialize(actual, bool, location)
      @actual   = actual
      @bool     = bool
      @location = location
    end

    attr_reader :actual, :bool, :location

    def _done()
      NOT_YET.delete(self.__id__)
    end
    private :_done

    def self.report_not_yet()
      #; [!3nksf] reports if 'ok{}' called but assertion not performed.
      return if NOT_YET.empty?
      NOT_YET.each_value do |ass|
        $stderr.write "** warning: ok() is called but not tested yet (at #{ass.location})\n"
      end
      #; [!f92q4] clears remained objects.
      NOT_YET.clear()
    end

    def __assert(result)
      raise FAIL_EXCEPTION, yield unless result
    end

    def NOT()
      #; [!63dde] toggles internal boolean.
      @bool = ! @bool
      #; [!g775v] returns self.
      self
    end

    def ==(expected)
      _done()
      #; [!1iun4] raises assertion error when failed.
      #; [!eyslp] is avaialbe with NOT.
      __assert(@bool == (@actual == expected)) {
        if @bool && ! (@actual == expected) \
            && @actual.is_a?(String) && expected.is_a?(String) \
            && (@actual =~ /\n/ || expected =~ /\n/)
          #; [!3xnqv] shows context diff when both actual and expected are text.
          diff = Util.unified_diff(expected, @actual, "--- $<expected>\n+++ $<actual>\n")
          "$<actual> == $<expected>: failed.\n#{diff}"
        else
          op = @bool ? '==' : '!='
          "$<actual> #{op} $<expected>: failed.\n"\
          "    $<actual>:   #{@actual.inspect}\n"\
          "    $<expected>: #{expected.inspect}"
        end
      }
      #; [!c6p0e] returns self when passed.
      self
    end

    def !=(expected)    # Ruby >= 1.9
      _done()
      #; [!90tfb] raises assertion error when failed.
      #; [!l6afg] is avaialbe with NOT.
      __assert(@bool == (@actual != expected)) {
        op = @bool ? '!=' : '=='
        "$<actual> #{op} $<expected>: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}"
      }
      #; [!iakbb] returns self when passed.
      self
    end

    def ===(expected)
      _done()
      #; [!42f6a] raises assertion error when failed.
      #; [!vhvyu] is avaialbe with NOT.
      __assert(@bool == (@actual === expected)) {
        s = "$<actual> === $<expected>"
        s = "!(#{s})" unless @bool
        "#{s}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}"
      }
      #; [!uh8bm] returns self when passed.
      self
    end

    def __assert_op(bool, op1, op2, expected)
      __assert(@bool == bool) {
        "#{@actual.inspect} #{@bool ? op1 : op2} #{expected.inspect}: failed."
      }
    end
    private :__assert_op

    def >(expected)
      _done()
      #; [!vjjuq] raises assertion error when failed.
      #; [!73a0t] is avaialbe with NOT.
      __assert_op(@actual > expected, '>', '<=', expected)
      #; [!3j7ty] returns self when passed.
      self
    end

    def >=(expected)
      _done()
      #; [!isdfc] raises assertion error when failed.
      #; [!3dgmh] is avaialbe with NOT.
      __assert_op(@actual >= expected, '>=', '<', expected)
      #; [!75iqw] returns self when passed.
      self
    end

    def <(expected)
      _done()
      #; [!ukqa0] raises assertion error when failed.
      #; [!gwvdl] is avaialbe with NOT.
      __assert_op(@actual < expected, '<', '>=', expected)
      #; [!vkwcc] returns self when passed.
      self
    end

    def <=(expected)
      _done()
      #; [!ordwe] raises assertion error when failed.
      #; [!mcb9w] is avaialbe with NOT.
      __assert_op(@actual <= expected, '<=', '>', expected)
      #; [!yk7t2] returns self when passed.
      self
    end

    def __assert_match(result, op1, op2, expected)
      __assert(@bool == !!result) {
        msg = "$<actual> #{@bool ? op1 : op2} $<expected>: failed.\n"\
              "    $<expected>: #{expected.inspect}\n"
        if @actual =~ /\n\z/
          msg + "    $<actual>:   <<'END'\n#{@actual}END\n"
        else
          msg + "    $<actual>:   #{@actual.inspect}\n"
        end
      }
    end
    private :__assert_match

    def =~(expected)
      _done()
      #; [!xkldu] raises assertion error when failed.
      #; [!2aa6f] is avaialbe with NOT.
      __assert_match(@actual =~ expected, '=~', '!~', expected)
      #; [!acypf] returns self when passed.
      self
    end

    def !~(expected)    # Ruby >= 1.9
      _done()
      #; [!58udu] raises assertion error when failed.
      #; [!iuf5j] is avaialbe with NOT.
      __assert_match(@actual !~ expected, '!~', '=~', expected)
      #; [!xywdr] returns self when passed.
      self
    end

    def in_delta?(expected, delta)
      _done()
      #; [!f3zui] raises assertion error when failed.
      #; [!t7liw] is avaialbe with NOT.
      __assert(@bool == !!((@actual - expected).abs < delta)) {
        eq = @bool ? '' : ' == false'
        "($<actual> - $<expected>).abs < #{delta}#{eq}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}\n"\
        "    ($<actual> - $<expected>).abs: #{(@actual - expected).abs.inspect}"
      }
      #; [!m0791] returns self when passed.
      self
    end

    def same?(expected)
      _done()
      #; [!ozbf4] raises assertion error when failed.
      #; [!dwtig] is avaialbe with NOT.
      __assert(@bool == !! @actual.equal?(expected)) {
        eq = @bool ? '' : ' == false'
        "$<actual>.equal?($<expected>)#{eq}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}\n"
      }
      #; [!yk7zo] returns self when passed.
      self
    end

    def method_missing(method_name, *args)
      _done()
      #; [!yjnxb] enables to handle boolean methods.
      #; [!ttow6] raises NoMethodError when not a boolean method.
      method_name.to_s =~ /\?\z/  or
        super
      begin
        ret = @actual.__send__(method_name, *args)
      rescue NoMethodError, TypeError => ex
        #; [!f0ekh] skip top of backtrace when NoMethodError raised.
        while !ex.backtrace.empty? && ex.backtrace[0].start_with?(__FILE__)
          ex.backtrace.shift()
        end
        raise
      end
      #; [!cun59] fails when boolean method failed returned false.
      #; [!4objh] is available with NOT.
      if ret == true || ret == false
        __assert(@bool == ret) {
          args = args.empty? ? '' : "(#{args.collect {|x| x.inspect }.join(', ')})"
          eq = @bool ? '' : ' == false'
          "$<actual>.#{method_name}#{args}#{eq}: failed.\n"\
          "    $<actual>:   #{@actual.inspect}"
        }
      #; [!sljta] raises TypeError when boolean method returned non-boolean value.
      else
        raise TypeError, "ok(): #{@actual.class}##{method_name}() expected to return true or false, but got #{ret.inspect}."
      end
      #; [!7bbrv] returns self when passed.
      self
    end

    def raise?(expected=Exception, errmsg=nil)
      _done()
      proc_obj = @actual
      if @bool
        #; [!wbwdo] raises assertion error when failed.
        ex = nil
        begin
          proc_obj.call
        rescue Exception => ex
          ex.is_a?(expected)  or
            __assert(false) { "Expected #{expected.inspect} to be raised but got #{ex.class}." }
        end
        #; [!vnc6b] sets exceptio object into '#exception' attribute.
        (class << proc_obj; self; end).class_eval { attr_accessor :exception }
        proc_obj.exception = ex
        __assert(! ex.nil?) { "Expected #{expected.inspect} to be raised but nothing raised." }
        #; [!tpxlv] accepts string or regexp as error message.
        case errmsg
        when nil;     # do nothing
        when Regexp
          __assert(ex.message =~ errmsg) {
            "$error_message =~ #{errmsg.inspect}: failed.\n"\
            "    $error_message: #{ex.message.inspect}"
          }
        else
          __assert(errmsg == ex.message) {
            "$error_message == #{errmsg.inspect}: failed.\n"\
            "    $error_message: #{ex.message.inspect}"
          }
        end
      else
        #; [!spzy2] is available with NOT.
        ! errmsg  or
          raise ArgumentError, "#{errmsg.inspect}: NOT.raise?() can't take errmsg."
        begin
          proc_obj.call
        rescue Exception => ex
          __assert(! ex.is_a?(expected)) {
            "#{expected.inspect} should not be raised but got #{ex.inspect}."
          }
        end
      end
      #; [!y1b28] returns self when passed.
      self
    end

    def in?(expected)
      _done()
      #; [!9rm8g] raises assertion error when failed.
      #; [!singl] is available with NOT.
      __assert(@bool == !! expected.include?(@actual)) {
        eq = @bool ? '' : ' == false'
        "$<expected>.include?($<actual>)#{eq}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}"
      }
      #; [!jzoxg] returns self when passed.
      self
    end

    def include?(expected)
      _done()
      #; [!960j7] raises assertion error when failed.
      #; [!55git] is available with NOT.
      __assert(@bool == !! @actual.include?(expected)) {
        eq = @bool ? '' : ' == false'
        "$<actual>.include?($<expected>)#{eq}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}\n"\
        "    $<expected>: #{expected.inspect}"
      }
      #; [!2hddj] returns self when passed.
      self
    end

    def attr(name, expected)
      _done()
      #; [!79tgn] raises assertion error when failed.
      #; [!cqnu3] is available with NOT.
      val = @actual.__send__(name)
      __assert(@bool == (expected == val)) {
        op = @bool ? '==' : '!='
        "$<actual>.#{name} #{op} $<expected>: failed.\n"\
        "    $<actual>.#{name}: #{val.inspect}\n"\
        "    $<expected>: #{expected.inspect}"\
      }
      #; [!lz3lb] returns self when passed.
      self
    end

    def attrs(keyvals={})
      _done()
      #; [!7ta0s] raises assertion error when failed.
      #; [!s0pnk] is available with NOT.
      keyvals.each {|name, expected| attr(name, expected) }
      #; [!rtq9f] returns self when passed.
      self
    end

    def keyval(key, expected)
      _done()
      #; [!vtrlz] raises assertion error when failed.
      #; [!mmpwz] is available with NOT.
      val = @actual[key]
      __assert(@bool == (expected == val)) {
        op = @bool ? '==' : '!='
        "$<actual>[#{key.inspect}] #{op} $<expected>: failed.\n"\
        "    $<actual>[#{key.inspect}]: #{val.inspect}\n"\
        "    $<expected>: #{expected.inspect}"\
      }
      #; [!byebv] returns self when passed.
      self
    end
    alias item keyval      # for compatibility with minitest-ok

    def keyvals(keyvals={})
      _done()
      #; [!fyvmn] raises assertion error when failed.
      #; [!js2j2] is available with NOT.
      keyvals.each {|name, expected| keyval(name, expected) }
      #; [!vtw22] returns self when passed.
      self
    end
    alias items keyvals    # for compatibility with minitest-ok

    def length(n)
      _done()
      #; [!1y787] raises assertion error when failed.
      #; [!kryx2] is available with NOT.
      __assert(@bool == (@actual.length == n)) {
        op = @bool ? '==' : '!='
        "$<actual>.length #{op} #{n}: failed.\n"\
        "    $<actual>.length: #{@actual.length}\n"\
        "    $<actual>:   #{actual.inspect}"
      }
      #; [!l9vnv] returns self when passed.
      self
    end

    def truthy?
      _done()
      #; [!3d94h] raises assertion error when failed.
      #; [!8rmgp] is available with NOT.
      __assert(@bool == (!!@actual == true)) {
        op = @bool ? '==' : '!='
        "!!$<actual> #{op} true: failed.\n"\
        "    $<actual>:   #{@actual.inspect}"
      }
      #; [!nhmuk] returns self when passed.
      self
    end

    def falsy?
      _done()
      #; [!7o48g] raises assertion error when failed.
      #; [!i44q6] is available with NOT.
      __assert(@bool == (!!@actual == false)) {
        op = @bool ? '==' : '!='
        "!!$<actual> #{op} false: failed.\n"\
        "    $<actual>:   #{@actual.inspect}"
      }
      #; [!w1vm6] returns self when passed.
      self
    end

    def __assert_fs(bool, s)
      __assert(@bool == bool) {
        "#{s}#{@bool ? '' : ' == false'}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}"
      }
    end
    private :__assert_fs

    def file_exist?
      _done()
      #; [!69bs0] raises assertion error when failed.
      #; [!r1mze] is available with NOT.
      __assert_fs(File.file?(@actual) , "File.file?($<actual>)")
      #; [!6bcpp] returns self when passed.
      self
    end

    def dir_exist?
      _done()
      #; [!vfh7a] raises assertion error when failed.
      #; [!qtllp] is available with NOT.
      __assert_fs(File.directory?(@actual), "File.directory?($<actual>)")
      #; [!8qe7u] returns self when passed.
      self
    end

    def symlink_exist?
      _done()
      #; [!qwngl] raises assertion error when failed.
      #; [!cgpbt] is available with NOT.
      __assert_fs(File.symlink?(@actual), "File.symlink?($<actual>)")
      #; [!ugfi3] returns self when passed.
      self
    end

    def not_exist?
      _done()
      #; [!ja84s] raises assertion error when failed.
      #; [!to5z3] is available with NOT.
      __assert(@bool == ! File.exist?(@actual)) {
        "File.exist?($<actual>)#{@bool ? ' == false' : ''}: failed.\n"\
        "    $<actual>:   #{@actual.inspect}"
      }
      #; [!1ujag] returns self when passed.
      self
    end

  end


  class ScopeObject

    def initialize()
      @children = []
      @fixtures = {}
    end

    attr_accessor :parent, :children, :before, :after, :before_all, :after_all, :fixtures
    attr_accessor :_klass, :_prefix  #:nodoc:

    def add_child(child)
      if child.is_a?(ScopeObject)
        child.parent.nil?  or
          raise ArgumentError, "add_child(): can't add child scope which already belongs to other."
        child.parent = self
      end
      @children << child
    end

    def get_fixture_info(name)
      return @fixtures[name]
      #@fixtures ? @fixtures[name] : nil   # or [nil, nil, nil]?
    end

    def new_context()
      return @_klass.new
    end

    def accept_runner(runner, *args)
      raise NotImplementedError, "#{self.class.name}#accept_runner(): not implemented yet."
    end

    def _repr(depth=0, buf="")
      indent = "  " * depth
      buf << "#{indent}-\n"
      instance_variables().sort.each do |name|
        next if name.to_s == "@children"
        buf << "#{indent}  #{name}: #{instance_variable_get(name).inspect}\n"
      end
      @children.each {|child| child._repr(depth+1, buf) }
      return buf
    end

    def +@
      self
    end

  end


  class FileScopeObject < ScopeObject

    attr_accessor :filename

    def initialize(filename=nil)
      super()
      @filename = filename
    end

    def accept_runner(runner, *args)
      return runner.run_topic(self, *args)
    end

  end


  class TopicObject < ScopeObject

    def initialize(target=nil, tag=nil)
      super()
      @target = target
      @tag    = tag
    end

    attr_reader :target, :tag

    def accept_runner(runner, *args)
      return runner.run_topic(self, *args)
    end

    def filter_match?(pattern)
      return File.fnmatch?(pattern, @target.to_s, File::FNM_EXTGLOB)
    end

    def tag_match?(pattern)
      return false if @tag.nil?
      return [@tag].flatten.any? {|tag| File.fnmatch?(pattern, tag.to_s, File::FNM_EXTGLOB) }
    end

  end


  module ScopeClassMethods

    def before(&block);     @_scope.before     = block;  end
    def after(&block);      @_scope.after      = block;  end
    def before_all(&block); @_scope.before_all = block;  end
    def after_all(&block);  @_scope.after_all  = block;  end

    def fixture(name, &block)
      location = caller(1).first
      argnames = block.arity > 0 ? Util.block_argnames(block, location) : nil
      @_scope.fixtures[name] = [block, argnames, location]
    end

    def topic(target, tag: nil, &block)
      topic = TopicObject.new(target, tag)
      @_scope.add_child(topic)
      klass = Class.new(self)
      klass.class_eval do
        extend ScopeClassMethods
        include SpecHelper
        @_scope = topic
      end
      klass.class_eval(&block)
      topic._klass = klass
      topic._prefix = '*'
      return topic
    end

    def case_when(desc, tag: nil, &block)
      return __case_when("When #{desc}", tag, &block)
    end

    def case_else(tag: nil, &block)
      return __case_when("Else", tag, &block)
    end

    def __case_when(desc, tag, &block)
      obj = topic(desc, tag: tag, &block)
      obj._prefix = '-'
      return obj
    end
    private :__case_when

    def spec(desc, tag: nil, &block)
      location = caller(1).first
      if block
        argnames = Util.block_argnames(block, location)
      else
        block = proc { raise TodoException, "not implemented yet" }
        argnames = []
      end
      spec = SpecObject.new(desc, block, argnames, location, tag)
      @_scope.add_child(spec)
      spec._prefix = '-'
      return spec
    end

  end


  def self.__scope(depth, &block)
    @_in_scope = true
    filename = caller(depth).first =~ /:\d+/ ? $` : nil
    filename = filename.sub(/\A\.\//, '')
    scope = FileScopeObject.new(filename)
    klass = Class.new
    klass.class_eval do
      extend ScopeClassMethods
      @_scope = scope
    end
    klass.class_eval(&block)
    scope._klass = klass
    @_in_scope = nil
    return scope
  end

  def self.scope(&block)
    ! @_in_scope  or
      raise OktestError, "scope() is not nestable."
    scope = __scope(2, &block)
    TOPLEVEL_SCOPES << scope
    return scope
  end

  def self.global_scope(&block)
    ! @_in_scope  or
      raise OktestError, "global_scope() is not nestable."
    GLOBAL_SCOPE._klass.class_eval(&block)
    return GLOBAL_SCOPE
  end

  TOPLEVEL_SCOPES = []
  GLOBAL_SCOPE    = __scope(1) { nil }


  class SpecObject

    def initialize(desc, block, argnames, location, tag=nil)
      @desc = desc
      @block = block
      @argnames = argnames
      @location = location   # necessary when raising fixture not found error
      @tag      = tag
    end

    attr_reader :desc, :block, :argnames, :location, :tag #:nodoc:
    attr_accessor :_prefix   #:nodoc:

    def accept_runner(runner, *args)       #:nodoc:
      runner.run_spec(self, *args)
    end

    def filter_match?(pattern)
      return File.fnmatch?(pattern, @desc.to_s, File::FNM_EXTGLOB)
    end

    def tag_match?(pattern)
      return false if @tag.nil?
      return [@tag].flatten.any? {|tag| File.fnmatch?(pattern, tag.to_s, File::FNM_EXTGLOB) }
    end

    def _repr(depth=0, buf="")       #:nodoc:
      buf << "  " * depth << "- #{@desc}\n"
      return buf
    end

    def -@
      self
    end

  end


  module SpecHelper

    attr_accessor :_TODO, :_at_end_blocks

    def ok()
      location = caller(1).first
      actual = yield
      ass = Oktest::AssertionObject.new(actual, true, location)
      Oktest::AssertionObject::NOT_YET[ass.__id__] = ass
      return ass
    end

    def not_ok()
      location = caller(1).first
      actual = yield
      ass = Oktest::AssertionObject.new(actual, false, location)
      Oktest::AssertionObject::NOT_YET[ass.__id__] = ass
      return ass
    end

    def skip_when(condition, reason)
      raise SkipException, reason if condition
    end

    def TODO()
      @_TODO = true
    end

    def at_end(&block)
      (@_at_end_blocks ||= []) << block
    end

    def capture_sio(input="", tty: false, &b)
      require 'stringio' unless defined?(StringIO)
      bkup = [$stdin, $stdout, $stderr]
      #; [!53mai] takes $stdin data.
      $stdin  = sin  = StringIO.new(input)
      #; [!1kbnj] captures $stdio and $stderr
      $stdout = sout = StringIO.new
      $stderr = serr = StringIO.new
      #; [!6ik8b] can simulate tty.
      if tty
        def sin.tty?; true; end
        def sout.tty?; true; end
        def serr.tty?; true; end
      end
      #; [!4j494] returns outpouts of stdout and stderr.
      yield sout, serr
      return sout.string, serr.string
    ensure
      #; [!wq8a9] recovers stdio even when exception raised.
      $stdin, $stdout, $stderr = bkup
    end

    def __do_dummy(val, recover, &b)
      if block_given?()
        begin
          return yield val
        ensure
          recover.call
        end
      else
        at_end(&recover)
        return val
      end
    end
    private :__do_dummy

    def dummy_file(filename=nil, content=nil, encoding: 'utf-8', &b)
      #; [!3mg26] generates temporary filename if 1st arg is nil.
      filename ||= "_tmpfile_#{rand().to_s[2...8]}"
      #; [!yvfxq] raises error when dummy file already exists.
      ! File.exist?(filename)  or
        raise ArgumentError, "dummy_file('#{filename}'): temporary file already exists."
      #; [!7e0bo] creates dummy file.
      File.write(filename, content, encoding: encoding)
      recover = proc { File.unlink(filename) if File.exist?(filename) }
      #; [!nvlkq] returns filename.
      #; [!ky7nh] can take block argument.
      return __do_dummy(filename, recover, &b)
    end

    def dummy_dir(dirname=nil, &b)
      #; [!r14uy] generates temporary directory name if 1st arg is nil.
      dirname ||= "_tmpdir_#{rand().to_s[2...8]}"
      #; [!zypj6] raises error when dummy dir already exists.
      ! File.exist?(dirname)  or
        raise ArgumentError, "dummy_dir('#{dirname}'): temporary directory already exists."
      #; [!l34d5] creates dummy directory.
      require 'fileutils' unless defined?(FileUtils)
      FileUtils.mkdir_p(dirname)
      #; [!01gt7] removes dummy directory even if it contains other files.
      recover = proc { FileUtils.rm_rf(dirname) if File.exist?(dirname) }
      #; [!jxh30] returns directory name.
      #; [!tfsqo] can take block argument.
      return __do_dummy(dirname, recover, &b)
    end

    def dummy_values(hashobj, keyvals={}, &b)
      #; [!hgwg2] changes hash value temporarily.
      prev_values = {}
      key_not_exists = {}
      keyvals.each do |k, v|
        if hashobj.key?(k)
          prev_values[k] = hashobj[k]
        else
          key_not_exists[k] = true
        end
        hashobj[k] = v
      end
      #; [!jw2kx] recovers hash values.
      recover = proc do
        key_not_exists.each {|k, _| hashobj.delete(k) }
        prev_values.each {|k, v| hashobj[k] = v }
      end
      #; [!w3r0p] returns keyvals.
      #; [!pwq6v] can take block argument.
      return __do_dummy(keyvals, recover, &b)
    end

    def dummy_attrs(object, keyvals={}, &b)
      #; [!4vd73] changes object attributes temporarily.
      prev_values = {}
      keyvals.each do |k, v|
        prev_values[k] = object.__send__(k)
        object.__send__("#{k}=", v)
      end
      #; [!fi0t3] recovers attribute values.
      recover = proc do
        prev_values.each {|k, v| object.__send__("#{k}=", v) }
      end
      #; [!27yeh] returns keyvals.
      #; [!j7tvp] can take block argument.
      return __do_dummy(keyvals, recover, &b)
    end

    def dummy_ivars(object, keyvals={}, &b)
      #; [!rnqiv] changes instance variables temporarily.
      prev_values = {}
      keyvals.each do |k, v|
        prev_values[k] = object.instance_variable_get("@#{k}")
        object.instance_variable_set("@#{k}", v)
      end
      #; [!8oirn] recovers instance variables.
      recover = proc do
        prev_values.each {|k, v| object.instance_variable_set("@#{k}", v) }
      end
      #; [!01dc8] returns keyvals.
      #; [!myzk4] can take block argument.
      return __do_dummy(keyvals, recover, &b)
    end

    def recorder()
      #; [!qwrr8] loads 'benry/recorder' automatically.
      require 'benry/recorder' unless defined?(Benry::Recorder)
      #; [!glfvx] creates Benry::Recorder object.
      return Benry::Recorder.new
    end

  end


  class Visitor

    def start()
      #; [!5zonp] visits topics and specs and calls callbacks.
      #; [!gkopz] doesn't change Oktest::TOPLEVEL_SCOPES.
      Oktest::TOPLEVEL_SCOPES.each do |scope|
        scope.children.each {|c| c.accept_runner(self, 0, nil) }
      end
    end

    def run_topic(topic, depth, parent)   #:nodoc:
      #; [!x8r9w] calls on_topic() callback on topic.
      if topic._prefix == '*'
        on_topic(topic.target, topic.tag, depth) do
          topic.children.each {|c| c.accept_runner(self, depth+1, topic) }
        end
      #; [!qh0q3] calls on_case() callback on case_when or case_else.
      else
        on_case(topic.target, topic.tag, depth) do
          topic.children.each {|c| c.accept_runner(self, depth+1, topic) }
        end
      end
    end

    def run_spec(spec, depth, parent)   #:nodoc:
      #; [!41uyj] calls on_spec() callback.
      on_spec(spec.desc, spec.tag, depth)
    end

    def on_topic(topic_target, tag, depth)
      yield
    end

    def on_case(case_cond, tag, depth)
      yield
    end

    def on_spec(spec_desc, tag, depth)
    end

  end


  STATUSES = [:PASS, :FAIL, :ERROR, :SKIP, :TODO]


  class Runner

    def initialize(reporter)
      @reporter = reporter
    end

    def run_topic(topic, depth, parent)
      @reporter.enter_topic(topic, depth)
      #; [!i3yfv] calls 'before_all' and 'after_all' blocks.
      call_before_all_block(topic)
      topic.children.each do |child|
        child.accept_runner(self, depth+1, topic)
      end
      call_after_all_block(topic)
      @reporter.exit_topic(topic, depth)
    end

    def run_spec(spec, depth, parent)
      @reporter.enter_spec(spec, depth)
      #; [!u45di] runs spec block with context object which allows to call methods defined in topics.
      topic = parent
      context = new_context(topic, spec)
      #; [!yagka] calls 'before' and 'after' blocks with context object as self.
      call_before_blocks(topic, context)
      status = :PASS
      ex = nil
      #; [!yd24o] runs spec body, catching assertions or exceptions.
      begin
        if spec.argnames.empty?
          call_spec_block(spec, context)
        else
          values = get_fixture_values(spec.argnames, topic, spec, context)
          call_spec_block(spec, context, *values)
        end
      rescue NoMemoryError   => ex;  raise ex
      rescue SignalException => ex;  raise ex
      rescue FAIL_EXCEPTION  => ex;  status = :FAIL
      rescue SKIP_EXCEPTION  => ex;  status = :SKIP
      rescue TODO_EXCEPTION  => ex;  status = :TODO
      rescue Exception       => ex;  status = :ERROR
      end
      #; [!68cnr] if TODO() called in spec...
      if context._TODO
        #; [!6ol3p] changes PASS status to FAIL because test passed unexpectedly.
        if status == :PASS
          status = :FAIL
          ex = FAIL_EXCEPTION.new("spec should be failed (because not implemented yet), but passed unexpectedly.")
        #; [!6syw4] changes FAIL status to TODO because test failed expectedly.
        elsif status == :FAIL
          status = :TODO
          ex = TODO_EXCEPTION.new("not implemented yet")
        end
        ex.set_backtrace([spec.location])
      end
      #; [!dihkr] calls 'at_end' blocks, even when exception raised.
      begin
        call_at_end_blocks(context)
      #; [!76g7q] calls 'after' blocks even when exception raised.
      ensure
        call_after_blocks(topic, context)
      end
      @reporter.exit_spec(spec, depth, status, ex, parent)
    end

    def run_all()
      #; [!xrisl] runs topics and specs.
      #; [!dth2c] clears filescopes list.
      @reporter.enter_all(self)
      while (scope = TOPLEVEL_SCOPES.shift)
        run_filescope(scope)
      end
      @reporter.exit_all(self)
    end

    def run_filescope(filescope)
      @reporter.enter_file(filescope.filename)
      #; [!5anr7] calls before_all and after_all blocks.
      call_before_all_block(filescope)
      filescope.children.each do |child|
        child.accept_runner(self, 0, nil)
      end
      call_after_all_block(filescope)
      @reporter.exit_file(filescope.filename)
    end

    private

    def new_context(topic, spec)
      return topic.new_context()
    end

    def get_fixture_values(names, topic, spec, context)
      return FixtureManager.instance.get_fixture_values(names, topic, spec, context)
    end

    def _call_blocks_parent_first(topic, name, obj)
      blocks = []
      while topic
        block = topic.__send__(name)
        blocks << block if block
        topic = topic.parent
      end
      blocks.reverse.each {|blk| obj.instance_eval(&blk) }
      blocks.clear
    end

    def _call_blocks_child_first(topic, name, obj)
      while topic
        block = topic.__send__(name)
        obj.instance_eval(&block) if block
        topic = topic.parent
      end
    end

    def call_before_blocks(topic, spec)
      _call_blocks_parent_first(topic, :before, spec)
    end

    def call_after_blocks(topic, spec)
      _call_blocks_child_first(topic, :after, spec)
    end

    def call_before_all_block(topic)
      block = topic.before_all
      topic.instance_eval(&block) if block
    end

    def call_after_all_block(topic)
      block = topic.after_all
      topic.instance_eval(&block) if block
    end

    def call_spec_block(spec, context, *args)
      if args.empty?
        context.instance_eval(&spec.block)
      else
        context.instance_exec(*args, &spec.block)
      end
    end

    def call_at_end_blocks(context)
      blocks = context._at_end_blocks
      if blocks
        blocks.reverse_each {|block| context.instance_eval(&block) }
        blocks.clear
      end
    end

  end


  RUNNER = Runner


  class FixtureManager

    def self.instance()
      #; [!jsi9q] returns same object every time.
      return @instance ||= self.new
    end

    def get_fixture_values(names, topic, spec, context, location=nil, resolved={}, resolving=[])
      #; [!w6ffs] resolves 'this_topic' fixture name as target objec of current topic.
      resolved[:this_topic] ||= topic.target
      #; [!ja2ew] resolves 'this_spec' fixture name as description of current spec.
      resolved[:this_spec]  ||= spec.desc
      #; [!v587k] resolves fixtures.
      location ||= spec.location
      return names.collect {|name|
        #; [!np4p9] raises error when loop exists in dependency.
        ! resolving.include?(name)  or
          raise _looped_dependency_error(name, resolving, location)
        get_fixture_value(name, topic, spec, context, location, resolved, resolving)
      }
    end

    def get_fixture_value(name, topic, spec, context, location=nil, resolved={}, resolving=[])
      return resolved[name] if resolved.key?(name)
      location ||= spec.location
      tuple = topic.get_fixture_info(name)
      if tuple
        block, argnames, location = tuple
        #; [!2esaf] resolves fixture dependencies.
        if argnames
          resolving << name
          args = get_fixture_values(argnames, topic, spec, context, location, resolved, resolving)
          (popped = resolving.pop) == name  or
            raise "** assertion failed: name=#{name.inspect}, resolvng[-1]=#{popped.inspect}"
          #; [!4xghy] calls fixture block with context object as self.
          val = context.instance_exec(*args, &block)
        else
          val = context.instance_eval(&block)
        end
        #; [!8t3ul] caches fixture value to call fixture block only once per spec.
        resolved[name] = val
        return val
      elsif topic.parent
        #; [!4chb9] traverses parent topics if fixture not found in current topic.
        return get_fixture_value(name, topic.parent, spec, context, location, resolved, resolving)
      elsif ! topic.equal?(GLOBAL_SCOPE)
        #; [!wt3qk] suports global scope.
        return get_fixture_value(name, GLOBAL_SCOPE, spec, context, location, resolved, resolving)
      else
        #; [!nr79z] raises error when fixture not found.
        ex = FixtureNotFoundError.new("#{name}: fixture not found. (spec: #{spec.desc})")
        ex.set_backtrace([location])
        raise ex
      end
    end

    private

    def _looped_dependency_error(name, resolving, location)
      resolving << name
      i = resolving.index(name)
      s1 = resolving[0...i].join('->')
      s2 = resolving[i..-1].join('=>')
      loop = s1.empty? ? s2 : "#{s1}->#{s2}"
      #location = $1 if location =~ /(.*:\d+)/
      ex = LoopedDependencyError.new("fixture dependency is looped: #{loop}")
      ex.set_backtrace([location])
      return ex
    end

  end


  class FixtureNotFoundError < StandardError
  end

  class LoopedDependencyError < StandardError
  end


  class Reporter

    def enter_all(runner); end
    def exit_all(runner); end
    def enter_file(filename); end
    def exit_file(filename); end
    def enter_topic(topic, depth); end
    def exit_topic(topic, depth); end
    def enter_spec(spec, depth); end
    def exit_spec(spec, depth, status, error, parent); end
    #
    def counts; {}; end

  end


  class BaseReporter < Reporter

    LABELS = { :PASS=>'pass', :FAIL=>'Fail', :ERROR=>'ERROR', :SKIP=>'Skip', :TODO=>'TODO' }
    CHARS  = { :PASS=>'.', :FAIL=>'f', :ERROR=>'E', :SKIP=>'s', :TODO=>'t' }


    def initialize
      @exceptions = []
      @counts = {}
    end

    attr_reader :counts

    def enter_all(runner)
      #; [!pq3ia] initalizes counter by zero.
      reset_counts()
      @start_at = Time.now
    end

    def exit_all(runner)
      #; [!wjp7u] prints footer with elapsed time.
      elapsed = Time.now - @start_at
      puts footer(elapsed)
    end

    def enter_file(filename)
    end

    def exit_file(filename)
    end

    def enter_topic(topic, depth)
    end

    def exit_topic(topic, depth)
    end

    def enter_spec(spec, depth)
    end

    def exit_spec(spec, depth, status, ex, parent)
      #; [!r6yge] increments counter according to status.
      @counts[status] += 1
      #; [!nupb4] keeps exception info when status is FAIL or ERROR.
      @exceptions << [spec, status, ex, parent] if status == :FAIL || status == :ERROR
    end

    protected

    def reset_counts()
      #; [!oc29s] clears counters to zero.
      STATUSES.each {|sym| @counts[sym] = 0 }
    end

    def print_exceptions()
      #; [!fbr16] prints assertion failures and excerptions with separator.
      sep = '-' * 70
      @exceptions.each do |tuple|
        puts sep
        print_exc(*tuple)
        tuple.clear
      end
      #; [!2s9r2] prints nothing when no fails nor errors.
      puts sep if ! @exceptions.empty?
      #; [!ueeih] clears exceptions.
      @exceptions.clear
    end

    def print_exc(spec, status, ex, topic)
      #; [!5ara3] prints exception info of assertion failure.
      #; [!pcpy4] prints exception info of error.
      label = Color.status(status, LABELS[status])
      path = Color.topic(spec_path(spec, topic))
      puts "[#{label}] #{path}"
      print_exc_backtrace(ex, status)
      print_exc_message(ex, status)
    end

    def print_exc_backtrace(ex, status)
      #; [!ocxy6] prints backtrace info and lines in file.
      rexp = FILENAME_FILTER
      prev_file = prev_line = nil
      ex.backtrace.each_with_index do |str, i|
        #; [!jbped] skips backtrace of oktest.rb when assertion failure.
        #; [!cfkzg] don't skip first backtrace entry when error.
        next if str =~ rexp && ! (i == 0 && status == :ERROR)
        linestr = nil
        if str =~ /:(\d+)/
          file = $`         # file path
          line = $1.to_i    # line number
          next if file == prev_file && line == prev_line
          linestr = Util.file_line(file, line) if str && File.exist?(file)
          prev_file, prev_line = file, line
        end
        puts "    #{str}"
        puts "        #{linestr.strip}"  if linestr
      end
    end

    FILENAME_FILTER = %r`/(?:oktest|minitest/unit|test/unit(?:/assertions|/testcase)?)(?:\.rbc?)?:` #:nodoc:

    def print_exc_message(ex, status)
      #; [!hr7jn] prints detail of assertion failed.
      #; [!pd41p] prints detail of exception.
      if status == :FAIL
        msg = "#{ex}"
      else
        msg = "#{ex.class.name}: #{ex}"
      end
      lines = []
      msg.each_line {|line| lines << line }
      puts lines.shift.chomp
      puts lines.join.chomp unless lines.empty?
      puts ex.diff if ex.respond_to?(:diff) && ex.diff   # for oktest.rb
    end

    def footer(elapsed)
      #; [!iy4uo] calculates total count of specs.
      total = 0; @counts.each {|_, v| total += v }
      #; [!2nnma] includes count of each status.
      arr = STATUSES.collect {|st|
        s = "#{st.to_s.downcase}:#{@counts[st]}"
        @counts[st] == 0 ? s : Color.status(st, s)
      }
      #; [!fp57l] includes elapsed time.
      #; [!r5y02] elapsed time format is adjusted along to time length.
      hhmmss = Util.hhmmss(elapsed)
      #; [!gx0n2] builds footer line.
      return "## total:#{total} (#{arr.join(', ')}) in #{hhmmss}s"
    end

    def spec_path(spec, topic)
      #; [!dv6fu] returns path string from top topic to current spec.
      arr = [spec.desc]
      while topic && topic.is_a?(TopicObject)
        arr << topic.target.to_s if topic.target
        topic = topic.parent
      end
      return arr.reverse.join(" > ")
    end

  end


  class VerboseReporter < BaseReporter
    #; [!6o9nw] reports topic name and spec desc.

    LABELS = { :PASS=>'pass', :FAIL=>'Fail', :ERROR=>'ERROR', :SKIP=>'Skip', :TODO=>'TODO' }

    def enter_topic(topic, depth)
      super
      puts "#{'  ' * depth}#{topic._prefix} #{Color.topic(topic.target)}"
    end

    def exit_topic(topic, depth)
      print_exceptions()
    end

    def enter_spec(spec, depth)
      if $stdout.tty?
        str = "#{'  ' * depth}#{spec._prefix} [    ] #{spec.desc}"
        print Util.strfold(str, 79)
        $stdout.flush
      end
    end

    def exit_spec(spec, depth, status, error, parent)
      super
      if $stdout.tty?
        print "\r"    # clear line
        $stdout.flush
      end
      label = Color.status(status, LABELS[status] || '???')
      msg = "#{'  ' * depth}- [#{label}] #{spec.desc}"
      msg << " " << Color.reason("(reason: #{error.message})") if status == :SKIP
      puts msg
    end

  end


  class SimpleReporter < BaseReporter
    #; [!xfd5o] reports filename.

    def enter_file(filename)
      print "#{filename}: "
    end

    def exit_file(filename)
      puts()
      print_exceptions()
    end

    def exit_spec(spec, depth, status, error, parent)
      super
      print Color.status(status, CHARS[status] || '?')
      $stdout.flush
    end

  end


  class PlainReporter < BaseReporter
    #; [!w842j] reports results only.

    def exit_all(runner)
      elapsed = Time.now - @start_at
      puts()
      print_exceptions()
      puts footer(elapsed)
    end

    def exit_spec(spec, depth, status, error, parent)
      super
      print Color.status(status, CHARS[status] || '?')
      $stdout.flush
    end

  end


  REPORTER_CLASS = VerboseReporter


  REPORTER_CLASSES = {
    'verbose' => VerboseReporter,  'v' => VerboseReporter,
    'simple'  => SimpleReporter,   's' => SimpleReporter,
    'plain'   => PlainReporter,    'p' => PlainReporter,
  }


  def self.run(opts={})
    return if TOPLEVEL_SCOPES.empty?
    klass = (opts[:style] ? REPORTER_CLASSES[opts[:style]] : REPORTER_CLASS)  or
      raise ArgumentError, "#{opts[:style].inspect}: unknown style."
    reporter = klass.new
    runner = Runner.new(reporter)
    runner.run_all()
    TOPLEVEL_SCOPES.clear
    counts = reporter.counts
    return counts[:FAIL] + counts[:ERROR]
  end


  module Util

    module_function

    def file_line(filename, linenum)
      #; [!4z65g] returns nil if file not exist or not a file.
      return nil unless File.file?(filename)
      #; [!4a2ji] caches recent file content for performance reason.
      @__cache ||= [nil, []]
      if @__cache[0] != filename
        #; [!wtrl5] recreates cache data if other file requested.
        @__cache[0] = filename
        @__cache[1].clear
        @__cache[1] = lines = File.open(filename, 'rb') {|f| f.to_a }
      else
        lines = @__cache[1]
      end
      #; [!162e1] returns line string.
      return lines[linenum-1]
    end

    def block_argnames(block, location)
      #; [!a9n46] returns nil if argument is nil.
      return nil unless block
      #; [!7m81p] returns empty array if block has no parameters.
      return [] if block.arity <= 0
      #; [!n3g63] returns parameter names of block.
      if block.respond_to?(:parameters)
        argnames = block.parameters.collect {|pair| pair.last }
      else
        location =~ /:(\d+)/
        filename = $`
        linenum  = $1.to_i
        File.file?(filename)  or
          raise ArgumentError, "block_argnames(): #{filename.inspect}: source file not found."
        linestr = file_line(filename, linenum) || ""
        linestr =~ /(?:\bdo|\{) *\|(.*)\|/  or
          raise ArgumentError, "spec(): can't detect block parameters at #{filename}:#{linenum}"
        argnames = $1.split(/,/).collect {|var| var.strip.intern }
      end
      return argnames
    end

    def strfold(str, width=80, mark='...')
      #; [!wb7m8] returns string as it is if string is not long.
      return str if str.bytesize <= width
      #; [!a2igb] shorten string if it is enough long.
      return str[0, width - mark.length] + mark if str.ascii_only?
      #; [!0gjye] supports non-ascii characters.
      limit = width - mark.length
      w = len = 0
      str.each_char do |ch|
        w += ch.bytesize == 1 ? 1 : 2
        break if w >= limit
        len += 1
      end
      str = str[0, len] + mark if w >= limit
      return str
    end

    def hhmmss(n)
      h, n = n.divmod(60*60)
      m, s = n.divmod(60)
      #; [!shyl1] converts 400953.444 into '111:22:33.4'.
      #; [!vyi2v] converts 5025.678 into '1:23:45.7'.
      return "%d:%02d:%04.1f" % [h, m, s] if h > 0
      #; [!pm4xf] converts 754.888 into '12:34.9'.
      #; [!lwewr] converts 83.444 into '1:23.4'.
      return "%d:%04.1f" % [m, s]         if m > 0
      #; [!ijx52] converts 56.8888 into '56.9'.
      return "%.1f" % s                   if s >= 10
      #; [!2kra2] converts 9.777 into '9.78'.
      return "%.2f" % s                   if s >= 1
      #; [!4aomb] converts 0.7777 into '0.778'.
      return "%.3f" % s
    end

    def _text2lines(text, no_newline_msg=nil)
      lines = []
      text.each_line {|line| line.chomp!; lines << line }
      lines[-1] << no_newline_msg if no_newline_msg && text[-1] && text[-1] != ?\n
      return lines
    end
    private :_text2lines

    ## platform independent, but requires 'diff-lcs' gem
    def unified_diff(text_old, text_new, label="--- old\n+++ new\n", context=3)
      #; [!rnx4f] checks whether text string ends with newline char.
      msg = "\\ No newline at end of string"
      lines_old = _text2lines(text_old, msg)
      lines_new = _text2lines(text_new, msg)
      #; [!wf4ns] calculates unified diff from two text strings.
      buf = [label]
      len = 0
      prevhunk = hunk = nil
      diffs = Diff::LCS.diff(lines_old, lines_new)
      diffs.each do |diff|
        hunk = Diff::LCS::Hunk.new(lines_old, lines_new, diff, context, len)
        if hunk.overlaps?(prevhunk)
          hunk.unshift(prevhunk)
        else
          buf << prevhunk.diff(:unified) << "\n"
        end if prevhunk
        len = hunk.file_length_difference
        prevhunk = hunk
      end
      buf << prevhunk.diff(:unified) << "\n" if prevhunk
      return buf.join()
    end

    ## platform depend, but not require extra library
    def diff_unified(text_old, text_new, label="--- old\n+++ new\n", context=3)
      #; [!ulyq5] returns unified diff string of two text strings.
      #; [!6tgum] detects whether char at end of file is newline or not.
      tmp_old = "_tmp.old.#{rand()}"
      tmp_new = "_tmp.new.#{rand()}"
      File.open(tmp_old, 'w') {|f| f.write(text_old) }
      File.open(tmp_new, 'w') {|f| f.write(text_new) }
      begin
        #diff = `diff -u #{tmp_old} #{tmp_new}`
        diff = `diff --unified=#{context} #{tmp_old} #{tmp_new}`
      ensure
        File.unlink(tmp_old)
        File.unlink(tmp_new)
      end
      diff.sub!(/\A\-\-\-.*\n\+\+\+.*\n/, label.to_s)
      return diff
    end

    ## when diff-lcs is not installed then use diff command
    begin
      require 'diff/lcs'
      #require 'diff/lcs/string'
      require 'diff/lcs/hunk'
    rescue LoadError
      alias _unified_diff unified_diff
      alias unified_diff diff_unified
      class << self
        alias _unified_diff unified_diff
        alias unified_diff diff_unified
      end
    end

  end


  class Config

    @os_windows      = RUBY_PLATFORM =~ /mswin|mingw/i
    @auto_run        = true
    @color_available = ! @os_windows || ENV['COLORTERM'] =~ /color|24bit/i
    @color_enabled   = @color_available && $stdout.tty?
    @diff_command    = @os_windows ? "diff.exe -u" : "diff -u"

    class << self
      attr_accessor :auto_run, :color_available, :color_enabled
    end

  end


  class Filter

    def initialize(topic_pattern, spec_pattern, tag_pattern, negative: false)
      @topic_pattern = topic_pattern
      @spec_pattern  = spec_pattern
      @tag_pattern   = tag_pattern
      @negative      = negative
    end

    def filter_toplevel_scope!(scope)
      _filter!(scope.children)
    end

    private

    def _filter!(children)
      #; [!6to6n] can filter by multiple tag name.
      #; [!r6g6a] supports negative filter by topic.
      #; [!doozg] supports negative filter by spec.
      #; [!ntv44] supports negative filter by tag name.
      topic_pat = @topic_pattern
      spec_pat  = @spec_pattern
      tag_pat   = @tag_pattern
      positive  = ! @negative
      children.collect! {|item|
        case item
        when TopicObject
          #; [!osoq2] can filter topics by full name.
          #; [!wzcco] can filter topics by pattern.
          if topic_pat && item.filter_match?(topic_pat)
            positive ? item : nil
          #; [!eirmu] can filter topics by tag name.
          elsif tag_pat && item.tag_match?(tag_pat)
            positive ? item : nil
          #; [!mz6id] can filter nested topics.
          else
            _filter!(item.children) ? item : nil
          end
        when SpecObject
          #; [!0kw9c] can filter specs by full name.
          #; [!fd8wt] can filter specs by pattern.
          if spec_pat && item.filter_match?(spec_pat)
            positive ? item : nil
          #; [!6sq7g] can filter specs by tag name.
          elsif tag_pat && item.tag_match?(tag_pat)
            positive ? item : nil
          #; [!1jphf] can filter specs from nested topics.
          else
            positive ? nil : item
          end
        else
          item
        end
      }
      children.compact!
      return !children.empty?
    end

  end

  FILTER_CLASS = Filter


  module Color

    module_function

    def normal  s;  return s; end
    def bold    s;  return "\x1b[0;1m#{s}\x1b[22m"; end
    def black   s;  return "\x1b[1;30m#{s}\x1b[0m"; end
    def red     s;  return "\x1b[1;31m#{s}\x1b[0m"; end
    def green   s;  return "\x1b[1;32m#{s}\x1b[0m"; end
    def yellow  s;  return "\x1b[1;33m#{s}\x1b[0m"; end
    def blue    s;  return "\x1b[1;34m#{s}\x1b[0m"; end
    def magenta s;  return "\x1b[1;35m#{s}\x1b[0m"; end
    def cyan    s;  return "\x1b[1;36m#{s}\x1b[0m"; end
    def white   s;  return "\x1b[1;37m#{s}\x1b[0m"; end

    def topic  s; Config.color_enabled ? bold(s)   : s; end
    def spec   s; Config.color_enabled ? normal(s) : s; end
    def pass   s; Config.color_enabled ? blue(s)   : s; end
    def fail   s; Config.color_enabled ? red(s)    : s; end
    def error  s; Config.color_enabled ? red(s)    : s; end
    def skip   s; Config.color_enabled ? yellow(s) : s; end
    def todo   s; Config.color_enabled ? yellow(s) : s; end
    def reason s; Config.color_enabled ? yellow(s) : s; end
    def status(status, s); __send__(status.to_s.downcase, s); end

  end


  class TestGenerator

    def initialize(styleoption=nil)
      @styleoption = styleoption
    end
    attr_reader :styleoption

    def parse(io)
      #; [!5mzd3] parses ruby code.
      tree = _parse(io, [], nil)
      return tree
    end

    def _parse(io, tree, end_indent)
      while (line = io.gets())
        case line
        when /^([ \t]*)end\b/
          return tree if $1 == end_indent
        when /^([ \t]*)(module|class|def) +(\w+[.:\w]*)/
          indent, keyword, topic = $1, $2, $3
          next if line =~ /\bend$/
          if keyword == 'def'
            topic = topic =~ /^self\./ ? ".#{$'}" : "\##{topic}"
          end
          newtree = []
          _parse(io, newtree, indent)
          tree << [indent, keyword, topic, newtree]
        when /^([ \t]*)\#[:;] (.*)/
          indent, keyword, spec = $1, 'spec', $2
          tree << [indent, keyword, spec]
        end
      end
      end_indent == nil  or
        raise "parse error: end_indent=#{end_indent.inspect}"
      return tree
    end
    private :_parse

    def transform(tree, depth=1)
      #; [!te7zw] converts tree into test code.
      buf = []
      tree.each do |tuple|
        _transform(tuple, depth, buf)
      end
      buf.pop() if buf[-1] == "\n"
      return buf.join()
    end

    def _transform(tuple, depth, buf)
      #; [!q5duk] supports 'unaryop' style option.
      unaryop = @styleoption == 'unaryop'
      indent  = '  ' * (depth - 1)
      keyword = tuple[1]
      if keyword == 'spec'
        _, _, spec = tuple
        escaped = spec.gsub(/"/, '\\\"')
        buf << "\n"
        buf << "#{indent}- spec(\"#{escaped}\")\n"    if unaryop
        buf << "#{indent}  spec \"#{escaped}\"\n" unless unaryop
      else
        _, _, topic, children = tuple
        topic += '()' if keyword == 'def'
        topic_ = keyword == 'def' ? "'#{topic}'" : topic
        buf << "\n"
        buf << "#{indent}+ topic(#{topic_}) do\n"     if unaryop
        buf << "#{indent}  topic #{topic_} do\n"  unless unaryop
        buf << "\n" unless keyword == 'def'
        children.each do |child_tuple|
          _transform(child_tuple, depth+1, buf)
        end
        buf << "\n"
        buf << "#{indent}  end  # #{topic}\n"
        buf << "\n"
      end
    end
    private :_transform

    def generate(io)
      #; [!5hdw4] generates test code.
      tree = parse(io)
      return <<END
# coding: utf-8

require 'oktest'

Oktest.scope do

#{transform(tree, 1)}

end
END
    end

  end


  class MainApp

    def self.main(argv=nil)
      #; [!tb6sx] returns 0 when no errors raised.
      #; [!d5mql] returns 1 when a certain error raised.
      argv ||= ARGV
      begin
        status = self.new.run(*argv)  or raise "** internal error"
        return status
      #; [!jr49p] reports error when unknown option specified.
      #; [!uqomj] reports error when required argument is missing.
      #; [!8i755] reports error when argument is invalid.
      rescue OptionParser::ParseError => ex
        case ex
        when OptionParser::InvalidOption   ; s = "unknown option."
        when OptionParser::InvalidArgument ; s = "invalid argument."
        when OptionParser::MissingArgument ; s = "argument required."
        else                               ; s = nil
        end
        msg = s ? "#{ex.args.join(' ')}: #{s}" : ex.message
        $stderr.puts("#{File.basename($0)}: #{msg}")
        return 1
      end
    end

    def run(*args)
      color_enabled = nil
      opts = Options.new
      parser = option_parser(opts)
      filenames = parser.parse(args)
      #; [!9973n] '-h' or '--help' option prints help message.
      if opts.help
        puts help_message()
        return 0
      end
      #; [!qqizl] '--version' option prints version number.
      if opts.version
        puts VERSION
        return 0
      end
      #; [!uxh5e] '-g' or '--generate' option prints test code.
      #; [!wmxu5] '--generate=unaryop' option prints test code with unary op.
      if opts.generate
        print generate(filenames, opts.generate)
        return 0
      end
      #; [!6ro7j] '--color=on' option enables output coloring forcedly.
      #; [!vmw0q] '--color=off' option disables output coloring forcedly.
      if opts.color
        color_enabled = Config.color_enabled
        Config.color_enabled = (opts.color == 'on')
      end
      #
      $LOADED_FEATURES << __FILE__ unless $LOADED_FEATURES.include?(__FILE__) # avoid loading twice
      #; [!hiu5b] finds test scripts in directory and runs them.
      load_files(filenames)
      #; [!yz7g5] '-F topic=...' option filters topics.
      #; [!ww2mp] '-F spec=...' option filters specs.
      #; [!8uvib] '-F tag=...' option filters by tag name.
      #; [!m0iwm] '-F sid=...' option filters by spec id.
      #; [!noi8i] '-F' option supports negative filter.
      if opts.filter
        filter_obj = parse_filter_pattern(opts.filter)
        filter(filter_obj)
      end
      #; [!18qpe] runs test scripts.
      #; [!0qd92] '-s verbose' or '-sv' option prints test results in verbose mode.
      #; [!ef5v7] '-s simple' or '-ss' option prints test results in simple mode.
      #; [!244te] '-s plain' or '-sp' option prints test results in plain mode.
      Config.auto_run = false
      n_errors = Oktest.run(:style=>opts.style)
      #; [!dsrae] reports if 'ok()' called but assertion not performed.
      AssertionObject.report_not_yet()
      #; [!bzgiw] returns total number of failures and errors.
      return n_errors
    ensure
      #; [!937kw] recovers 'Config.color_enabled' value.
      Config.color_enabled = color_enabled if color_enabled != nil
    end

    private

    class Options   #:nodoc:
      attr_accessor :help, :version, :style, :filter, :color, :generate
    end

    def option_parser(opts)
      require 'optparse' unless defined?(OptionParser)
      parser = OptionParser.new
      parser.on('-h', '--help')    { opts.help    = true }
      parser.on(      '--version') { opts.version = true }
      parser.on('-s STYLE') {|val|
        REPORTER_CLASSES.key?(val)  or
          raise OptionParser::InvalidArgument, val
        opts.style = val
      }
      parser.on('-F PATTERN') {|val|
        #; [!71h2x] '-F ...' option will be error.
        val =~ /\A(topic|spec|tag|sid)(=|!=)/  or
          raise OptionParser::InvalidArgument, val
        opts.filter = val
      }
      parser.on(      '--color[={on|off}]') {|val|
        #; [!9nr94] '--color=true' option raises error.
        val.nil? || val == 'on' || val == 'off'  or
          raise OptionParser::InvalidArgument, val
        #; [!dptgn] '--color' is same as '--color=on'.
        opts.color = val || 'on'
      }
      parser.on('-g', '--generate[=styleoption]') {|val|
        val.nil? || val == 'unaryop'  or
          raise OptionParser::InvalidArgument, val
        opts.generate = val || true
      }
      return parser
    end

    def help_message(command=nil)
      command ||= File.basename($0)
      return <<END
Usage: #{command} [<options>] [<file-or-directory>...]
  -h, --help             : show help
      --version          : print version
  -s STYLE               : report style (verbose/simple/plain, or v/s/p)
  -F PATTERN             : filter topic or spec with pattern (see below)
      --color[={on|off}] : enable/disable output coloring forcedly
  -g, --generate         : generate test code skeleton from ruby file

Filter examples:
  $ oktest -F topic=Hello            # filter by topic
  $ oktest -F spec='*hello*'         # filter by spec
  $ oktest -F tag=name               # filter by tag name
  $ oktest -F tag!=name              # negative filter by tag name
  $ oktest -F tag='{name1,name2}'    # filter by multiple tag names
END
    end

    def load_files(filenames)
      filenames.each do |fname|
        File.exist?(fname)  or
          raise OptionParser::InvalidOption, "#{fname}: not found."
      end
      filenames.each do |fname|
        File.directory?(fname) ? load_dir(fname) : load(fname)
      end
    end

    def load_dir(dir, pattern=/^(test_.*|.*_test)\.rb$/)
      Dir.glob("#{dir}/**/*").sort.each do |path|
        next unless File.file?(path)
        load(path) if File.basename(path) =~ pattern
      end
    end

    def generate(filenames, styleoption)
      buf = []
      filenames.each do |fname|
        generator = TestGenerator.new(styleoption)
        File.open(fname) do |f|
          buf << generator.generate(f)
        end
      end
      return buf.join()
    end

    def parse_filter_pattern(pattern)
      #; [!gtpt1] parses 'sid=...' as filter pattern for spec.
      pattern = "spec#{$1}\\[!#{$2}\\]*" if pattern =~ /\Asid(=|!=)(.*)/  # filter by spec id
      #; [!xt364] parses 'topic=...' as filter pattern for topic.
      #; [!53ega] parses 'spec=...' as filter pattern for spec.
      #; [!go6us] parses 'tag=...' as filter pattern for tag.
      pat = {'topic'=>nil, 'spec'=>nil, 'tag'=>nil}
      pattern =~ /\A(\w+)(=|!=)/ && pat.key?($1)  or
        raise Exception, "** internal error: pattern=#{pattern.inspect}"
      pat[$1] = $'
      #; [!5hl7z] parses 'xxx!=...' as negative filter pattern.
      negative = ($2 == '!=')
      #; [!9dzmg] returns filter object.
      return FILTER_CLASS.new(pat['topic'], pat['spec'], pat['tag'], negative: negative)
    end

    def filter(filter_obj)
      TOPLEVEL_SCOPES.each do |filescope|
        filter_obj.filter_toplevel_scope!(filescope)
      end
    end

  end


  def self.main(argv=nil)
    status = MainApp.main(argv)
    exit(status)
  end

  def self.on_exit()     # :nodoc:
    Oktest.main() if self.auto_run?()
  end

  def self.auto_run?()   # :nodoc:
    exc = $!
    return false if exc && !exc.is_a?(SystemExit)
    return false if TOPLEVEL_SCOPES.empty?
    return Config.auto_run
  end


end


at_exit { Oktest.on_exit() }


if __FILE__ == $0
  $LOADED_FEATURES << File.expand_path(__FILE__)  # avoid loading oktest.rb twice
  Oktest.main()   # run test scripts
end
