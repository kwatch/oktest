###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

path = File.class_eval { expand_path(join(dirname(__FILE__), '..', 'lib')) }
$: << path unless $:.include?(path)

require 'test/unit'
require 'oktest'

Test::Unit::TestCase.class_eval { alias_method :eq, :assert_equal }


class Oktest::Util::CallTest < Test::Unit::TestCase

  def test_initialize
    obj = Oktest::Util::Call.new(:hello, ['world', 123], true)
    eq :hello, obj.name
    eq ['world', 123], obj.args
    eq true, obj.ret
  end

  def test_to_a
    obj = Oktest::Util::Call.new(:hello, ['world', 123], true)
    eq [:hello, ['world', 123], true], obj.to_a
  end

end


class Oktest::Util::FakeObjectTest < Test::Unit::TestCase

  def test_add_response
    obj = Oktest::Util::FakeObject.new
    #
    obj.add_response(:hello, 'world')
    eq true, obj.respond_to?(:hello)
    eq 'world', obj.hello(123)
    eq [:hello, [123], 'world'], obj._calls[0].to_a
    #
    obj.add_response(:hello2) do |name|
      "Hello #{name}!"
    end
    eq true, obj.respond_to?(:hello2)
    eq 'Hello SOS!', obj.hello2('SOS')
    eq [:hello2, ['SOS'], 'Hello SOS!'], obj._calls[1].to_a
  end

  def test_initialize
    obj = Oktest::Util::FakeObject.new
    eq 0, obj._calls.length
    #
    obj = Oktest::Util::FakeObject.new(:f1=>10, :f2=>proc {|x| x*2 })
    eq 20, obj.f2(obj.f1)
    eq [:f1, [],   10], obj._calls[0].to_a
    eq [:f2, [10], 20], obj._calls[1].to_a
  end

end


class Oktest::Util::TracerTest < Test::Unit::TestCase

  def setup
    @tr = Oktest::Util::Tracer.new
  end

  def test_trace_method
    s = "Mikuru"
    @tr.trace_method(s, :sub)
    eq 'Michiru', s.sub(/ku/, 'chi')
    eq [:sub, [/ku/, 'chi'], 'Michiru'], @tr[0].to_a
  end

  def test_fake_method
    s = "Yuki"
    @tr.fake_method(s, :hello, 'sos')
    eq 'sos', s.hello
    eq [:hello, [], 'sos'], @tr[0].to_a
    #
    @tr.fake_method(s, :hello2) {|name| "Hello #{name}!" }
    eq 'Hello SOS!', s.hello2('SOS')
    eq [:hello2, ['SOS'], 'Hello SOS!'], @tr[1].to_a
  end

  def test_fake_object
    obj = @tr.fake_object(:f1=>'sos', :f2=>proc {|*args| "<<#{args.inspect}>>" })
    eq 'sos', obj.f1
    eq '<<[1, false]>>', obj.f2(1, false)
  end

  def test_FUNC_trace_and_fake
    s = "Mikuru"
    @tr.trace_method(s, :gsub)
    @tr.fake_method(s, :hello) {|name| "Hello #{name}!" }
    obj = @tr.fake_object(:f1=>10, :f2=>proc {|x| 2*x})
    eq 'Hello Michiru!', s.hello(s.gsub(/ku/, 'chi'))
    eq 20, obj.f2(obj.f1)
    eq [:gsub, [/ku/, 'chi'], 'Michiru'], @tr[0].to_a
    eq [:hello, ['Michiru'], 'Hello Michiru!'], @tr[1].to_a
    eq [:f1, [],   10], @tr[2].to_a
    eq [:f2, [10], 20], @tr[3].to_a
  end

end
