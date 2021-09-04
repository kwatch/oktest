# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Item_TC < TC

  describe '#accept_visitor()' do
    it "[!b0e20] raises NotImplementedError." do
      assert_exc(NotImplementedError, "Oktest::Item#accept_visitor(): not implemented yet.") do
        Oktest::Item.new().accept_visitor(nil)
      end
    end
  end

  describe '#unlink_parent()' do
    it "[!5a0i9] raises NotImplementedError." do
      assert_exc(NotImplementedError, "Oktest::Item#unlink_parent(): not implemented yet.") do
        Oktest::Item.new().unlink_parent()
      end
    end
  end

  describe '#_repr()' do
    it "[!qi1af] raises NotImplementedError." do
      assert_exc(NotImplementedError, "Oktest::Item#_repr(): not implemented yet.") do
        Oktest::Item.new()._repr(0)
      end
    end
  end

end


class Node_TC < TC

  def setup()
  end

  def teardown()
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end


  describe '#add_child()' do
    it "[!1fyk9] keeps children." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      p.add_child(c)
      assert_eq p.instance_eval('@children'), [c]
    end
    it "[!w5r6l] returns self." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      ret = p.add_child(c)
      assert ret.equal?(p), "should be same"
    end
  end

  describe '#has_child?' do
    it "[!xb30d] return true when no children, else false." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      p.add_child(c)
      assert_eq p.has_child?, true
      assert_eq c.has_child?, false
    end
  end

  describe '#each_child()' do
    it "[!osoep] returns enumerator if block not given." do
      node = Oktest::Node.new(nil)
      assert_eq node.each_child.class, Enumerator
    end
    it "[!pve8m] yields block for each child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      arr = []
      p.each_child {|x| arr << x }
      assert_eq arr.length, 2
      assert_eq arr[0], c1
      assert_eq arr[1], c2
    end
    it "[!8z6un] returns nil." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      ret = p.each_child {|c| 123 }
      assert_eq ret, nil
    end
    it "[!p356a] change iteration order when subclass specified." do
      p  = Oktest::Node.new(nil)
      t1 = Oktest::TopicNode.new(p, "T1")
      s1 = Oktest::SpecLeaf.new(p, "S1")
      t2 = Oktest::TopicNode.new(p, "T2")
      s2 = Oktest::SpecLeaf.new(p, "S2")
      arr = []
      p.each_child(Oktest::SpecLeaf) {|x| arr << x }
      assert_eq arr[0], s1
      assert_eq arr[1], s2
      assert_eq arr[2], t1
      assert_eq arr[3], t2
    end
  end

  describe '#remove_child()' do
    it "[!hsomo] removes child at index." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      p.remove_child_at(0)
      children = p.each_child.to_a
      assert_eq children.length, 1
      assert_eq children[0], c2
    end
    it "[!hiz1b] returns removed child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      ret = p.remove_child_at(0)
      assert_eq ret, c1
    end
    it "[!7fhx1] unlinks reference between parent and child." do
      p  = Oktest::Node.new(nil)
      c1 = Oktest::Node.new(p)
      c2 = Oktest::Node.new(p)
      p.remove_child_at(1)
      assert_eq c2.parent, nil
      assert_eq c1.parent, p
    end
  end

  describe '#clear_children()' do
    it "[!o8xfb] removes all children." do
      p = Oktest::Node.new(nil)
      p.add_child(Oktest::Node.new(nil))
      p.add_child(Oktest::Node.new(nil))
      assert_eq p.has_child?, true
      p.clear_children()
      assert_eq p.has_child?, false
    end
    it "[!cvaq1] return self." do
      p = Oktest::Node.new(nil)
      assert p.clear_children().equal?(p)
    end
  end

  describe '#unlink_parent()' do
    it "[!59m52] clears '@parent' instance variable." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(p)
      assert_eq c.parent, p
      c.unlink_parent()
      assert_eq c.parent, nil
    end
    it "[!qksxv] returns parent object." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(p)
      ret = c.unlink_parent()
      assert_eq ret, p
    end
  end

  describe '#run_block_in_context_class()' do
    it "[!j9qdh] run block in context class." do
      x = Oktest::Node.new(nil)
      x.run_block_in_context_class { @_tmpvar = "<<00807>>" }
      val = x.context_class.instance_variable_get('@_tmpvar')
      assert_eq val, "<<00807>>"
    end
  end

  describe '#new_context_object()' do
    it "[!p271z] creates new context object." do
      x = Oktest::Node.new(nil)
      ctx = x.new_context_object()
      assert_eq ctx.class, x.context_class
      assert ctx.is_a?(Oktest::Context)
    end
    it "[!9hbxn] context object has 'ok()' method." do
      x = Oktest::Node.new(nil)
      ctx = x.new_context_object()
      assert ctx.respond_to?(:ok)
      assert ctx.respond_to?(:not_ok)
      assert ctx.respond_to?(:skip_when)
      assert ctx.respond_to?(:at_end)
    end
  end

  describe '#register_fixture_block()' do
    it "[!5ctsn] registers fixture name, block, and location." do
      x = Oktest::Node.new(nil)
      x.register_fixture_block(:foo, "file:123") {|a, b| "foobar" }
      assert x.fixtures[:foo][0].is_a?(Proc), "proc object expected"
      assert_eq x.fixtures[:foo][0].call(1, 2), "foobar"
      assert_eq x.fixtures[:foo][1], [:a, :b]
      assert_eq x.fixtures[:foo][2], "file:123"
      #
      x.register_fixture_block(:bar, "file:345") { "barbar" }
      assert_eq x.fixtures[:bar][0].call(), "barbar"
      assert_eq x.fixtures[:bar][1], nil
      assert_eq x.fixtures[:bar][2], "file:345"
    end
    it "[!hfcvo] returns self." do
      x = Oktest::Node.new(nil)
      ret = x.register_fixture_block(:foo, "file:123") { "foobar" }
      assert ret.equal?(x)
    end
  end

  describe '#get_fixture_block()' do
    it "[!f0105] returns fixture info." do
      x = Oktest::Node.new(nil)
      x.fixtures[:foo] = ["block", [:a, :b], "file:123"]
      assert_eq x.get_fixture_block(:foo), ["block", [:a, :b], "file:123"]
    end
  end

  describe '#register_hook_block()' do
    it "[!zb66o] registers block with key." do
      x = Oktest::Node.new(nil)
      x.register_hook_block(:before) { "<<42533>>" }
      x.register_hook_block(:after) { "<<46675>>" }
      assert_eq x.hooks[:before].call(), "<<42533>>"
      assert_eq x.hooks[:after].call(), "<<46675>>"
    end
  end

  describe '#get_hook_block()' do
    it "[!u3fc6] returns block corresponding to key." do
      x = Oktest::Node.new(nil)
      x.register_hook_block(:before) { "<<42533>>" }
      x.register_hook_block(:after) { "<<46675>>" }
      assert_eq x.get_hook_block(:before).call(), "<<42533>>"
      assert_eq x.get_hook_block(:after).call(), "<<46675>>"
    end
  end

  describe '#_repr()' do
    it "[!bt5j8] builds debug string." do
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
      #assert_eq result, expected
      assert result =~ Regexp.compile('\A'+expected), "not matched"
    end
  end

end


class ScopeNode_TC < TC

  describe '#accept_visitor()' do
    class DummyVisitor
      def visit_scope(*args)
        @_args = args
        "<<43746>>"
      end
      attr_reader :_args
    end
    it "[!vr6ko] invokes 'visit_spec()' method of visitor and returns result of it." do
      dummy = DummyVisitor.new()
      sc = Oktest::ScopeNode.new(nil, __FILE__)
      ret = sc.accept_visitor(dummy, 1, 2, 3)
      assert_eq dummy._args, [sc, 1, 2, 3]
      assert_eq ret, "<<43746>>"
    end
  end

end


class TopicNode_TC < TC

  def new_topic(target, tag: nil)
    return Oktest::TopicNode.new(nil, target, tag: tag)
  end

  describe '#accept_visitor()' do
    class DummyVisitor2
      def visit_topic(*args)
        @_args = args
        "<<55977>>"
      end
      attr_reader :_args
    end
    it "[!c1b33] invokes 'visit_topic()' method of visitor and returns result of it." do
      dummy = DummyVisitor2.new
      to = Oktest::TopicNode.new(nil, Array)
      ret = to.accept_visitor(dummy, 4, 5)
      assert_eq dummy._args, [to, 4, 5]
      assert_eq ret, "<<55977>>"
    end
  end

  describe '#@+' do
    it "[!tzorv] returns self." do
      to = new_topic('#foobar()')
      assert (+ to).equal?(to), "should be same"
    end
  end

end


class ScopeFunctions_TC < TC

  def startup
  end

  def teardown
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  def with_dummy_location(location)
    $_dummy_location = location
    Oktest.module_eval do
      class << self
        def caller(n)
          return [$_dummy_location]
        end
      end
    end
    yield
  ensure
    Oktest.module_eval do
      class << self
        remove_method :caller
      end
    end
    $_dummy_location = nil
  end

  describe 'Oktest.scope()' do
    it "[!vxoy1] creates new scope object." do
      x = Oktest.scope() { nil }
      assert_eq x.class, Oktest::ScopeNode
    end
    it "[!jmc4q] raises error when nested called." do
      begin                 ; x = 0
        assert_exc(Oktest::OktestError, "scope() and global_scope() are not nestable.") do
                            ; x = 1
          Oktest.scope do   ; x = 2
            Oktest.scope do ; x = 3
            end
          end
        end
        assert_eq x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
    end
    it "[!rsimc] adds scope object as child of THE_GLOBAL_SCOPE." do
      assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, false
      so = Oktest.scope do
      end
      assert_eq Oktest::THE_GLOBAL_SCOPE.has_child?, true
      assert_eq Oktest::THE_GLOBAL_SCOPE.each_child.to_a, [so]
    end
    it "[!kem4y] detects test script filename." do
      sc = Oktest.scope() { nil }
      assert_eq sc.filename, "test/node_test.rb"
    end
    it "[!6ullm] changes test script filename from absolute path to relative path." do
      with_dummy_location(Dir.pwd + "/tests/foo_test.rb:123") do
        sc = Oktest.scope() { nil }
        assert_eq sc.filename, "tests/foo_test.rb"
      end
      with_dummy_location("./t/bar_test.rb:456") do
        sc = Oktest.scope() { nil }
        assert_eq sc.filename, "t/bar_test.rb"
      end
    end
  end

  describe '#global_scope()' do
    it "[!fcmt2] not create new scope object." do
      go1 = Oktest.global_scope() { nil }
      assert_eq go1.class, Oktest::ScopeNode
      go2 = Oktest.global_scope() { nil }
      assert_eq go2, go1
      assert_eq go2, Oktest::THE_GLOBAL_SCOPE
    end
    it "[!flnpc] run block in the THE_GLOBAL_SCOPE object." do
      Oktest.global_scope do
        fixture :tmp_37531 do
          {id: 37531}
        end
      end
      assert Oktest::THE_GLOBAL_SCOPE.fixtures.key?(:tmp_37531)
      v = Oktest::THE_GLOBAL_SCOPE.fixtures[:tmp_37531][0].call
      assert_eq v, {id: 37531}
    end
    it "[!pe0g2] raises error when nested called." do
      args = [Oktest::OktestError, "scope() and global_scope() are not nestable."]
      begin                        ; x = 0
        assert_exc(*args) do       ; x = 1
          Oktest.global_scope do   ; x = 2
            Oktest.global_scope do ; x = 3
            end
          end
        end
        assert_eq x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      #
      begin                        ; x = 0
        assert_exc(*args) do       ; x = 1
          Oktest.scope do          ; x = 2
            Oktest.global_scope do ; x = 3
            end
          end
        end
        assert_eq x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      #
      begin                        ; x = 0
        assert_exc(*args) do       ; x = 1
          Oktest.global_scope do   ; x = 2
            Oktest.scope do        ; x = 3
            end
          end
        end
        assert_eq x, 2
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
    end
  end

end


class Context_TC < TC

  def new_node_with(&b)
    node = Oktest::Node.new(nil)
    cls = Class.new(Oktest::Context)
    cls.__node = node
    cls.class_eval(&b)
    return node
  end

  describe '#topic()' do
    it "[!0gfvq] creates new topic node." do
      node = new_node_with() do
        topic Dir, tag: "exp" do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      to = node.each_child.first
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, Dir
      assert_eq to.tag, "exp"
      assert_eq to._prefix, "*"
    end
  end

  describe '#case_when()' do
    it "[!g3cvh] returns topic object." do
      node = new_node_with() do
        case_when "condition..." do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      to = node.each_child.first
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, "When condition..."
      assert_eq to.tag, nil
      assert_eq to._prefix, "-"
    end
    it "[!ofw1i] target is a description starting with 'When '." do
      node = new_node_with() do
        case_when "condition..." do
        end
      end
      to = node.each_child.first
      assert_eq to.target, "When condition..."
    end
  end

  describe '#case_else()' do
    it "[!oww4b] returns topic object." do
      node = new_node_with() do
        case_else tag: "dev" do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      to = node.each_child.first
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, "Else"
      assert_eq to.tag, "dev"
      assert_eq to._prefix, "-"
    end
    it "[!j5gnp] target is a description which is 'Else'." do
      node = new_node_with() do
        case_else do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      to = node.each_child.first
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, "Else"
    end
    it "[!hs1to] 1st parameter is optional." do
      node = new_node_with() do
        case_else "(x < 0)" do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      to = node.each_child.first
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, "Else (x < 0)"
    end
  end

  describe '#scope()' do
    it "[!c8c8o] creates new spec object." do
      node = new_node_with() do
        spec "example #1", tag: "exp" do
        end
      end
      assert_eq node.each_child.to_a.length, 1
      sp = node.each_child.first
      assert_eq sp.class, Oktest::SpecLeaf
      assert_eq sp.desc, "example #1"
      assert_eq sp.tag, "exp"
      assert_eq sp._prefix, "-"
    end
    it "[!ala78] provides raising TodoException block if block not given." do
      node = new_node_with() do
        spec "example #3"
      end
      assert_eq node.each_child.to_a.length, 1
      sp = node.each_child.first
      assert_exc(Oktest::TodoException, "not implemented yet") do
        sp.block.call
      end
    end
    it "[!x48db] keeps called location only when block has parameters." do
      lineno = __LINE__ + 3
      node = new_node_with() do
        spec "example #4" do nil end
        spec "example #5" do |x| nil end
      end
      sp1, sp2 = node.each_child.to_a
      assert_eq sp1.location, nil
      assert sp2.location != nil, "not nil"
      assert sp2.location.start_with?("#{__FILE__}:#{lineno}:in")
    end
  end

  describe '#fixture()' do
    it "[!8wfrq] registers fixture factory block." do
      lineno = __LINE__ + 2
      node = new_node_with() do
        fixture :alice do
          {name: "alice"}
        end
      end
      assert_eq node.fixtures.length, 1
      assert    node.fixtures.key?(:alice), "key not registerd"
      assert    node.fixtures[:alice][0].is_a?(Proc), "block expected"
      assert_eq node.fixtures[:alice][1], nil
      assert    node.fixtures[:alice][2].start_with?("#{__FILE__}:#{lineno}:in ")
    end
    it "[!y3ks3] retrieves block parameter names." do
      node = new_node_with() do
        fixture :bob do |x, y|
          {name: "bob"}
        end
      end
      assert_eq node.fixtures[:bob][1], [:x, :y]
      #
      node = new_node_with() do
        fixture :charlie do
          {name: "charlie"}
        end
      end
      assert_eq node.fixtures[:charlie][1], nil
    end
  end

  describe '#before() ' do
    it "[!275zr] registers 'before' hook block." do
      x = new_node_with() do
        before { "<<78059>>" }
      end
      assert_eq x.get_hook_block(:before).call(), "<<78059>>"
    end
  end

  describe '#after() ' do
    it "[!ngkvz] registers 'after' hook block." do
      x = new_node_with() do
        after { "<<52091>>" }
      end
      assert_eq x.get_hook_block(:after).call(), "<<52091>>"
    end
  end

  describe '#before_all() ' do
    it "[!8v1y4] registers 'before_all' hook block." do
      x = new_node_with() do
        before_all { "<<42577>>" }
      end
      assert_eq x.get_hook_block(:before_all).call(), "<<42577>>"
    end
  end

  describe '#after_all() ' do
    it "[!0w5ik] registers 'after_all' hook block." do
      x = new_node_with() do
        after_all { "<<33326>>" }
      end
      assert_eq x.get_hook_block(:after_all).call(), "<<33326>>"
    end
  end

end


class SpecLeafTC < TC

  def startup
  end

  def teardown
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  def new_spec_object(desc="sample #1", tag: nil)
    sp = nil
    Oktest.scope do
      topic 'Example' do
        sp = spec(desc, tag: tag) { nil }
      end
    end
    return sp
  end

  describe '#run_block_in_context_object()' do
    it "[!tssim] run spec block in text object." do
      to = Oktest::TopicNode.new(nil, 'Example')
      sp = Oktest::SpecLeaf.new(to, "#sample 2") { @called = "<<29193>>" }
      ctx = to.new_context_object()
      assert_eq ctx.instance_variable_get('@called'), nil
      sp.run_block_in_context_object(ctx)
      assert_eq ctx.instance_variable_get('@called'), "<<29193>>"
    end
  end

  describe '#accept_visitor()' do
    class DummyVisitor3
      def visit_spec(*args)
        @_args = args
        "<<82980>>"
      end
      attr_reader :_args
    end
    it "[!ya32z] invokes 'visit_spec()' method of visitor and returns result of it." do
      dummy = DummyVisitor3.new
      sc = Oktest::SpecLeaf.new(nil, "sample")
      ret = sc.accept_visitor(dummy, 7, 8)
      assert_eq dummy._args, [sc, 7, 8]
      assert_eq ret, "<<82980>>"
    end
  end

  describe '#unlink_parent()' do
    it "[!e9sv9] do nothing." do
      to = Oktest::TopicNode.new(nil, "sample")
      sp = Oktest::SpecLeaf.new(to, "sample")
      ret = sp.unlink_parent()
      assert_eq ret, nil
    end
  end

  describe '#_repr()' do
    it "[!6nsgy] builds debug string." do
      sp1 = new_spec_object("sample #1")
      assert_eq sp1._repr(), "- sample #1\n"
      sp2 = new_spec_object("sample #2", tag: "exp")
      assert_eq sp2._repr(), "- sample #2 (tag: \"exp\")\n"
      assert_eq sp2._repr(2), "    - sample #2 (tag: \"exp\")\n"
    end
  end

  describe '#@-' do
    it "[!bua80] returns self." do
      sp = new_spec_object("sample #1")
      assert (- sp).equal?(sp), "should be same"
    end
  end

end
