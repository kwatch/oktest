# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 1.5.0 $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


class Item__Test
  extend NanoTest

  test_target 'Oktest::Item#accept_visitor()' do
    test_subject "[!b0e20] raises NotImplementedError." do
      exc = test_exception? NotImplementedError do
        Oktest::Item.new().accept_visitor(nil)
      end
      test_eq? exc.message, "Oktest::Item#accept_visitor(): not implemented yet."
    end
  end

  test_target 'Oktest::Item#unlink_parent()' do
    test_subject "[!5a0i9] raises NotImplementedError." do
      exc = test_exception? NotImplementedError do
        Oktest::Item.new().unlink_parent()
      end
      test_eq? exc.message, "Oktest::Item#unlink_parent(): not implemented yet."
    end
  end

  test_target 'Oktest::Item#_repr()' do
    test_subject "[!qi1af] raises NotImplementedError." do
      exc = test_exception? NotImplementedError do
        Oktest::Item.new()._repr(0)
      end
      test_eq? exc.message, "Oktest::Item#_repr(): not implemented yet."
    end
  end

end


class Node__Test
  extend NanoTest

  def self.test_scope(desc, &b)
    NanoTest.test_scope(desc, &b)
  ensure
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  test_target 'Oktest::Node#add_child()' do
    test_subject "[!1fyk9] keeps children." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      p.add_child(c)
      test_eq? p.instance_eval('@children'), [c]
    end
    test_subject "[!w5r6l] returns self." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      ret = p.add_child(c)
      test_ok? ret.equal?(p), msg: "should be same"
    end
  end

  test_target 'Oktest::Node#has_child?' do
    test_subject "[!xb30d] return true when no children, else false." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      p.add_child(c)
      test_eq? p.has_child?, true
      test_eq? c.has_child?, false
    end
  end

  test_target 'Oktest::Node#each_child()' do
    test_subject "[!osoep] returns enumerator if block not given." do
      node = Oktest::Node.new(nil)
      test_eq? node.each_child.class, Enumerator
    end
    test_subject "[!pve8m] yields block for each child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      arr = []
      p.each_child {|x| arr << x }
      test_eq? arr.length, 2
      test_eq? arr[0], c1
      test_eq? arr[1], c2
    end
    test_subject "[!8z6un] returns nil." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      ret = p.each_child {|c| 123 }
      test_eq? ret, nil
    end
  end

  test_target 'Oktest::Node#remove_child()' do
    test_subject "[!hsomo] removes child at index." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      p.remove_child_at(0)
      children = p.each_child.to_a
      test_eq? children.length, 1
      test_eq? children[0], c2
    end
    test_subject "[!hiz1b] returns removed child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      ret = p.remove_child_at(0)
      test_eq? ret, c1
    end
    test_subject "[!7fhx1] unlinks reference between parent and child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      p.remove_child_at(1)
      test_eq? c2.parent, nil
      test_eq? c1.parent, p
    end
  end

  test_target 'Oktest::Node#clear_children()' do
    test_subject "[!o8xfb] removes all children." do
      p = Oktest::Node.new(nil)
      p.add_child(Oktest::Node.new(nil))
      p.add_child(Oktest::Node.new(nil))
      test_eq? p.has_child?, true
      p.clear_children()
      test_eq? p.has_child?, false
    end
    test_subject "[!cvaq1] return self." do
      p = Oktest::Node.new(nil)
      test_ok? p.clear_children().equal?(p)
    end
  end

  test_target 'Oktest::Node#unlink_parent()' do
    test_subject "[!59m52] clears '@parent' instance variable." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(p)
      test_eq? c.parent, p
      c.unlink_parent()
      test_eq? c.parent, nil
    end
    test_subject "[!qksxv] returns parent object." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(p)
      ret = c.unlink_parent()
      test_eq? ret, p
    end
  end

  test_target 'Oktest::Node#run_block_in_context_class()' do
    test_subject "[!j9qdh] run block in context class." do
      x = Oktest::Node.new(nil)
      x.run_block_in_context_class { @_tmpvar = "<<00807>>" }
      val = x.context_class.instance_variable_get('@_tmpvar')
      test_eq? val, "<<00807>>"
    end
  end

  test_target 'Oktest::Node#new_context_object()' do
    test_subject "[!p271z] creates new context object." do
      x = Oktest::Node.new(nil)
      ctx = x.new_context_object()
      test_eq? ctx.class, x.context_class
      test_ok? ctx.is_a?(Oktest::Context)
    end
    test_subject "[!9hbxn] context object has 'ok()' method." do
      x = Oktest::Node.new(nil)
      ctx = x.new_context_object()
      test_ok? ctx.respond_to?(:ok)
      test_ok? ctx.respond_to?(:not_ok)
      test_ok? ctx.respond_to?(:skip_when)
      test_ok? ctx.respond_to?(:at_end)
    end
  end

  test_target 'Oktest::Node#register_fixture_block()' do
    test_subject "[!5ctsn] registers fixture name, block, and location." do
      x = Oktest::Node.new(nil)
      x.register_fixture_block(:foo, "file:123") {|a, b| "foobar" }
      test_ok? x.fixtures[:foo][0].is_a?(Proc), msg: "proc object expected"
      test_eq? x.fixtures[:foo][0].call(1, 2), "foobar"
      test_eq? x.fixtures[:foo][1], [:a, :b]
      test_eq? x.fixtures[:foo][2], "file:123"
      #
      x.register_fixture_block(:bar, "file:345") { "barbar" }
      test_eq? x.fixtures[:bar][0].call(), "barbar"
      test_eq? x.fixtures[:bar][1], nil
      test_eq? x.fixtures[:bar][2], "file:345"
    end
    test_subject "[!hfcvo] returns self." do
      x = Oktest::Node.new(nil)
      ret = x.register_fixture_block(:foo, "file:123") { "foobar" }
      test_ok? ret.equal?(x)
    end
  end

  test_target 'Oktest::Node#get_fixture_block()' do
    test_subject "[!f0105] returns fixture info." do
      x = Oktest::Node.new(nil)
      x.fixtures[:foo] = ["block", [:a, :b], "file:123"]
      test_eq? x.get_fixture_block(:foo), ["block", [:a, :b], "file:123"]
    end
  end

  test_target 'Oktest::Node#register_hook_block()' do
    test_subject "[!zb66o] registers block with key." do
      x = Oktest::Node.new(nil)
      x.register_hook_block(:before) { "<<42533>>" }
      x.register_hook_block(:after) { "<<46675>>" }
      test_eq? x.hooks[:before].call(), "<<42533>>"
      test_eq? x.hooks[:after].call(), "<<46675>>"
    end
  end

  test_target 'Oktest::Node#get_hook_block()' do
    test_subject "[!u3fc6] returns block corresponding to key." do
      x = Oktest::Node.new(nil)
      x.register_hook_block(:before) { "<<42533>>" }
      x.register_hook_block(:after) { "<<46675>>" }
      test_eq? x.get_hook_block(:before).call(), "<<42533>>"
      test_eq? x.get_hook_block(:after).call(), "<<46675>>"
    end
  end

  test_target 'Oktest::Node#_repr()' do
    test_subject "[!bt5j8] builds debug string." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(p)
      p.add_child(c)
      expected = <<'END'
- #<Oktest::Node:0x[0-9a-f]+>
  @context_class: #<Class:0x[0-9a-f]+>
  - #<Oktest::Node:0x[0-9a-f]+>
    @context_class: #<Class:0x[0-9a-f]+>
    @parent: #<Oktest::Node:0x[0-9a-f]+>
END
      result = p._repr()
      #test_eq? result, expected
      test_match? result, Regexp.compile('\A'+expected), msg: "not matched"
    end
  end

end


class ScopeNode__Test
  extend NanoTest

  test_target 'Oktest::ScopeNode#accept_visitor()' do
    class DummyVisitor
      def visit_scope(*args)
        @_args = args
        "<<43746>>"
      end
      attr_reader :_args
    end
    test_subject "[!vr6ko] invokes 'visit_spec()' method of visitor and returns result of it." do
      dummy = DummyVisitor.new()
      sc = Oktest::ScopeNode.new(nil, __FILE__)
      ret = sc.accept_visitor(dummy, 1, 2, 3)
      test_eq? dummy._args, [sc, 1, 2, 3]
      test_eq? ret, "<<43746>>"
    end
  end

end


class TopicNode__Test
  extend NanoTest

  def self.new_topic(target, tag: nil)
    return Oktest::TopicNode.new(nil, target, tag: tag)
  end

  test_target 'Oktest::TopicNode#run_block_in_context_class()' do
    test_subject "[!i2kvj] run block in context class." do
      topicobj = new_topic("foobar1")
      self_ = nil
      topicobj.run_block_in_context_class do
        self_ = self
      end
      test_ok? self_ < Oktest::Context
    end
    test_subject "[!pr3vj] run block with topic target as an argument." do
      topicobj = new_topic("foobar2")
      arg_ = nil
      topicobj.run_block_in_context_class do |arg|
        arg_ = arg
      end
      test_eq? arg_, "foobar2"
    end
  end

  test_target 'Oktest::TopicNode#accept_visitor()' do
    class DummyVisitor2
      def visit_topic(*args)
        @_args = args
        "<<55977>>"
      end
      attr_reader :_args
    end
    test_subject "[!c1b33] invokes 'visit_topic()' method of visitor and returns result of it." do
      dummy = DummyVisitor2.new
      to = Oktest::TopicNode.new(nil, Array)
      ret = to.accept_visitor(dummy, 4, 5)
      test_eq? dummy._args, [to, 4, 5]
      test_eq? ret, "<<55977>>"
    end
  end

  test_target 'Oktest::TopicNode#@+' do
    test_subject "[!tzorv] returns self." do
      to = new_topic('#foobar()')
      test_ok? (+ to).equal?(to), msg: "should be same"
    end
  end

end


class OktestFuncs__Test
  extend NanoTest

  def self.test_subject(desc, &b)
    super
  ensure
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  class DummyLocation # < Thread::Backtrace::Location
    def initialize(string)
      string =~ /([^:]+):(\d+)/
      @path = $1
      @lineno = $2
    end
    attr_reader :path, :lineno
  end

  def self.with_dummy_location(location)
    $_dummy_location = location
    Oktest.module_eval do
      class << self
        def caller(n, len=nil)
          return [$_dummy_location]
        end
        def caller_locations(n, len=nil)
          return [DummyLocation.new($_dummy_location)]
        end
      end
    end
    yield
  ensure
    Oktest.module_eval do
      class << self
        remove_method :caller
        remove_method :caller_locations
      end
    end
    $_dummy_location = nil
  end

  test_target 'Oktest.scope()' do
    test_subject "[!vxoy1] creates new scope object." do
      x = Oktest.scope() { nil }
      test_eq? x.class, Oktest::ScopeNode
    end
    test_subject "[!jmc4q] raises error when nested called." do
      begin                 ; x = 0
        exc = test_exception? Oktest::OktestError do
                            ; x = 1
          Oktest.scope do   ; x = 2
            Oktest.scope do ; x = 3
            end
          end
        end
        test_eq? exc.message, "scope() and global_scope() are not nestable."
        test_eq? x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
    end
    test_subject "[!rsimc] adds scope object as child of THE_GLOBAL_SCOPE." do
      test_eq? Oktest::THE_GLOBAL_SCOPE.has_child?, false
      so = Oktest.scope do
      end
      test_eq? Oktest::THE_GLOBAL_SCOPE.has_child?, true
      test_eq? Oktest::THE_GLOBAL_SCOPE.each_child.to_a, [so]
    end
    test_subject "[!kem4y] detects test script filename." do
      sc = Oktest.scope() { nil }
      test_eq? sc.filename, "test/node_test.rb"
    end
    test_subject "[!6ullm] changes test script filename from absolute path to relative path." do
      with_dummy_location(Dir.pwd + "/tests/foo_test.rb:123") do
        sc = Oktest.scope() { nil }
        test_eq? sc.filename, "tests/foo_test.rb"
      end
      with_dummy_location("./t/bar_test.rb:456") do
        sc = Oktest.scope() { nil }
        test_eq? sc.filename, "t/bar_test.rb"
      end
    end
  end

  test_target 'Oktest.global_scope()' do
    test_subject "[!fcmt2] not create new scope object." do
      go1 = Oktest.global_scope() { nil }
      test_eq? go1.class, Oktest::ScopeNode
      go2 = Oktest.global_scope() { nil }
      test_eq? go2, go1
      test_eq? go2, Oktest::THE_GLOBAL_SCOPE
    end
    test_subject "[!flnpc] run block in the THE_GLOBAL_SCOPE object." do
      Oktest.global_scope do
        fixture :tmp_37531 do
          {id: 37531}
        end
      end
      test_ok? Oktest::THE_GLOBAL_SCOPE.fixtures.key?(:tmp_37531)
      v = Oktest::THE_GLOBAL_SCOPE.fixtures[:tmp_37531][0].call
      test_eq? v, {id: 37531}
    end
    test_subject "[!pe0g2] raises error when nested called." do
      expected_errmsg = "scope() and global_scope() are not nestable."
      begin                        ; x = 0
        exc = test_exception? Oktest::OktestError do
                                   ; x = 1
          Oktest.global_scope do   ; x = 2
            Oktest.global_scope do ; x = 3
            end
          end
        end
        test_eq? exc.message, expected_errmsg
        test_eq? x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      #
      begin                        ; x = 0
        exc = test_exception? Oktest::OktestError do
                                   ; x = 1
          Oktest.scope do          ; x = 2
            Oktest.global_scope do ; x = 3
            end
          end
        end
        test_eq? exc.message, expected_errmsg

        test_eq? x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      #
      begin                        ; x = 0
        exc = test_exception? Oktest::OktestError do       ; x = 1
          Oktest.global_scope do   ; x = 2
            Oktest.scope do        ; x = 3
            end
          end
        end
        test_eq? exc.message, expected_errmsg
        test_eq? x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
    end
  end

  test_target 'Oktest.topic()' do
    test_subject "[!c5j3f] same as `Oktest.scope do topic target do ... end end`." do
      arg_ = nil
      Oktest.topic "FooBar" do |arg|
        arg_ = arg
      end
      test_eq? arg_, "FooBar"
    end
  end

end


class Context__Test
  extend NanoTest

  def self.new_node_with(&b)
    node = Oktest::Node.new(nil)
    cls = Class.new(Oktest::Context)
    cls.__node = node
    cls.class_eval(&b)
    return node
  end

  test_target 'Oktest::Context#topic()' do
    test_subject "[!0gfvq] creates new topic node." do
      node = new_node_with() do
        topic Dir, tag: "exp" do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, Dir
      test_eq? to.tag, "exp"
      test_eq? to._prefix, "*"
    end
  end

  test_target 'Oktest::Context#case_when()' do
    test_subject "[!g3cvh] returns topic object." do
      node = new_node_with() do
        case_when "condition..." do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "When condition..."
      test_eq? to.tag, nil
      test_eq? to._prefix, "-"
    end
    test_subject "[!ofw1i] target is a description starting with 'When '." do
      node = new_node_with() do
        case_when "condition..." do
        end
      end
      to = node.each_child.first
      test_eq? to.target, "When condition..."
    end
    test_subject "[!53qxv] not add 'When ' if description starts with it." do
      node = new_node_with() do
        case_when "when condition..." do
        end
      end
      to = node.each_child.first
      test_eq? to.target, "when condition..."
      #
      node = new_node_with() do
        case_when "[""!abc] when..." do
        end
      end
      to = node.each_child.first
      test_eq? to.target, "[""!abc] when..."
    end
  end

  test_target 'Oktest::Context#case_else()' do
    test_subject "[!oww4b] returns topic object." do
      node = new_node_with() do
        case_else tag: "dev" do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "Else"
      test_eq? to.tag, "dev"
      test_eq? to._prefix, "-"
    end
    test_subject "[!j5gnp] target is a description which is 'Else'." do
      node = new_node_with() do
        case_else do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "Else"
    end
    test_subject "[!3nn8d] not add 'Else ' if description starts with it." do
      node = new_node_with() do
        case_else "else (x < 0)" do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "else (x < 0)"
      #
      node = new_node_with() do
        case_else "[""!abc] else..." do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "[""!abc] else..."
    end
    test_subject "[!hs1to] 1st parameter is optional." do
      node = new_node_with() do
        case_else "(x < 0)" do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      to = node.each_child.first
      test_eq? to.class, Oktest::TopicNode
      test_eq? to.target, "Else (x < 0)"
    end
  end

  test_target 'Oktest::Context#scope()' do
    test_subject "[!c8c8o] creates new spec object." do
      node = new_node_with() do
        spec "example #1", tag: "exp" do
        end
      end
      test_eq? node.each_child.to_a.length, 1
      sp = node.each_child.first
      test_eq? sp.class, Oktest::SpecLeaf
      test_eq? sp.desc, "example #1"
      test_eq? sp.tag, "exp"
      test_eq? sp._prefix, "-"
    end
    test_subject "[!4vkbl] error when `fixture:` keyword arg is not a Hash object." do
      new_node_with() do
        spec "example #2", fixture: {x: 1} do end   # not raise anything
      end
      exc = test_exception? ArgumentError do
        new_node_with() do
          spec "example #2", fixture: "x: 1" do end
        end
      end
      test_eq? exc.message, 'spec(fixture: "x: 1"): fixture argument should be a Hash object, but got String object.'
    end
    test_subject "[!ala78] provides raising TodoException block if block not given." do
      node = new_node_with() do
        spec "example #3"
      end
      test_eq? node.each_child.to_a.length, 1
      sp = node.each_child.first
      exc = test_exception? Oktest::TodoException do
        sp.block.call
      end
      test_eq? exc.message, "not implemented yet"
    end
    test_subject "[!x48db] keeps called location only when block has parameters." do
      lineno = __LINE__ + 3
      node = new_node_with() do
        spec "example #4" do nil end
        spec "example #5" do |x| nil end
      end
      sp1, sp2 = node.each_child.to_a
      test_eq? sp1.location, nil
      test_ok? sp2.location != nil, msg: "not nil"
      test_ok? sp2.location.to_s.start_with?("#{__FILE__}:#{lineno}:in")
    end
  end

  test_target 'Oktest::Context#fixture()' do
    test_subject "[!8wfrq] registers fixture factory block." do
      lineno = __LINE__ + 2
      node = new_node_with() do
        fixture :alice do
          {name: "alice"}
        end
      end
      test_eq? node.fixtures.length, 1
      test_ok? node.fixtures.key?(:alice), msg: "key not registerd"
      test_ok? node.fixtures[:alice][0].is_a?(Proc), msg: "block expected"
      test_eq? node.fixtures[:alice][1], nil
      test_ok? node.fixtures[:alice][2].to_s.start_with?("#{__FILE__}:#{lineno}:in ")
    end
    test_subject "[!y3ks3] retrieves block parameter names." do
      node = new_node_with() do
        fixture :bob do |x, y|
          {name: "bob"}
        end
      end
      test_eq? node.fixtures[:bob][1], [:x, :y]
      #
      node = new_node_with() do
        fixture :charlie do
          {name: "charlie"}
        end
      end
      test_eq? node.fixtures[:charlie][1], nil
    end
  end

  test_target 'Oktest::Context#before() ' do
    test_subject "[!275zr] registers 'before' hook block." do
      x = new_node_with() do
        before { "<<78059>>" }
      end
      test_eq? x.get_hook_block(:before).call(), "<<78059>>"
    end
  end

  test_target 'Oktest::Context#after() ' do
    test_subject "[!ngkvz] registers 'after' hook block." do
      x = new_node_with() do
        after { "<<52091>>" }
      end
      test_eq? x.get_hook_block(:after).call(), "<<52091>>"
    end
  end

  test_target 'Oktest::Context#before_all() ' do
    test_subject "[!8v1y4] registers 'before_all' hook block." do
      x = new_node_with() do
        before_all { "<<42577>>" }
      end
      test_eq? x.get_hook_block(:before_all).call(), "<<42577>>"
    end
  end

  test_target 'Oktest::Context#after_all() ' do
    test_subject "[!0w5ik] registers 'after_all' hook block." do
      x = new_node_with() do
        after_all { "<<33326>>" }
      end
      test_eq? x.get_hook_block(:after_all).call(), "<<33326>>"
    end
  end

end


class SpecLeaf__Test
  extend NanoTest

  def self.test_subject(desc, &b)
    super
  ensure
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  def self.new_spec_object(desc="sample #1", tag: nil)
    sp = nil
    Oktest.scope do
      topic 'Example' do
        sp = spec(desc, tag: tag) { nil }
      end
    end
    return sp
  end

  test_target 'Oktest::SpecLeaf#run_block_in_context_object()' do
    test_subject "[!tssim] run spec block in text object." do
      to = Oktest::TopicNode.new(nil, 'Example')
      sp = Oktest::SpecLeaf.new(to, "#sample 2") { @called = "<<29193>>" }
      ctx = to.new_context_object()
      test_eq? ctx.instance_variable_get('@called'), nil
      sp.run_block_in_context_object(ctx)
      test_eq? ctx.instance_variable_get('@called'), "<<29193>>"
    end
  end

  test_target 'Oktest::SpecLeaf#accept_visitor()' do
    class DummyVisitor3
      def visit_spec(*args)
        @_args = args
        "<<82980>>"
      end
      attr_reader :_args
    end
    test_subject "[!ya32z] invokes 'visit_spec()' method of visitor and returns result of it." do
      dummy = DummyVisitor3.new
      sc = Oktest::SpecLeaf.new(nil, "sample")
      ret = sc.accept_visitor(dummy, 7, 8)
      test_eq? dummy._args, [sc, 7, 8]
      test_eq? ret, "<<82980>>"
    end
  end

  test_target 'Oktest::SpecLeaf#unlink_parent()' do
    test_subject "[!e9sv9] do nothing." do
      to = Oktest::TopicNode.new(nil, "sample")
      sp = Oktest::SpecLeaf.new(to, "sample")
      ret = sp.unlink_parent()
      test_eq? ret, nil
    end
  end

  test_target 'Oktest::SpecLeaf#_repr()' do
    test_subject "[!6nsgy] builds debug string." do
      sp1 = new_spec_object("sample #1")
      test_eq? sp1._repr(), "- sample #1\n"
      sp2 = new_spec_object("sample #2", tag: "exp")
      test_eq? sp2._repr(), "- sample #2 (tag: \"exp\")\n"
      test_eq? sp2._repr(2), "    - sample #2 (tag: \"exp\")\n"
    end
  end

  test_target 'Oktest::SpecLeaf#@-' do
    test_subject "[!bua80] returns self." do
      sp = new_spec_object("sample #1")
      test_ok? (- sp).equal?(sp), msg: "should be same"
    end
  end

end
