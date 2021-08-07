# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Node_TC < TC

  def setup()
  end

  def teardown()
    Oktest::TOPLEVEL_SCOPES.clear()
  end

  def prepare()
    Oktest.scope do
      topic 'Hello' do
        spec "hello spec", tag: 'new' do ok {"hello"} == "hello" end
      end
      topic 'Topic 832795' do
        topic Integer do
          spec "spec example #1" do ok {1+1} == 2 end
          spec "spec example #2", tag: 'new' do ok {1-1} == 0 end
        end
        topic Float, tag: 'exp' do
          spec "spec example #3" do ok {1.0+1.0} == 2.0 end
          spec "spec example #4" do ok {1.0-1.0} == 0.0 end
        end
        spec "spec example #5", tag: ['exp', 'new'] do ok {1%1} == 0 end
      end
    end
  end

  def run_filter(topic_pattern, spec_pattern, tag_pattern, negative: false)
    prepare()
    filter = Oktest::Filter.new(topic_pattern, spec_pattern, tag_pattern, negative: negative)
    Oktest.filter(filter)
    reporter = Oktest::VerboseReporter.new()
    sout, serr = capture('', tty: false) do
      Oktest::Runner.new(reporter).run_all()
    end
    assert_eq serr, ""
    return sout.sub(/^## total:.*\n/, '')
  end

  def uncolor(s)
    return s.gsub(/\x1b.*?m/, '')
  end


  describe '#add_child()' do
    it "[!1fyk9] keeps children." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      p.add_child(c)
      assert_eq p.children, [c]
    end
    it "[!w5r6l] returns self." do
      p = Oktest::Node.new(nil)
      c = Oktest::Node.new(nil)
      ret = p.add_child(c)
      assert ret.equal?(p), "should be same"
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

  describe '#accept_runner()' do
    it "[!olckb] raises NotImplementedError." do
      x = Oktest::Node.new(nil)
      begin
        x.accept_runner(Oktest::Runner.new(nil))
      rescue Exception => exc
        assert_eq exc.class, NotImplementedError
        assert_eq exc.message, "Oktest::Node#accept_runner(): not implemented yet."
      else
        assert false, "NotImplementedError expected."
      end
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

  describe '#filter_match?()' do
    it "[!lt56h] always returns false." do
      x = Oktest::Node.new(nil)
      ft = Oktest::Filter.new("*", "*", "*")
      assert_eq x.filter_match?(ft), false
    end
  end

  describe '#tag_match?()' do
    it "[!5kmcf] returns false if node has no tags." do
      x = Oktest::Node.new(nil, tag: nil)
      assert_eq x.tag_match?('*'), false
    end
    it "[!fmwfy] returns true if pattern matched to tag name." do
      x = Oktest::Node.new(nil, tag: 'deprecated')
      assert_eq x.tag_match?('deprecated'), true
      assert_eq x.tag_match?('dep*'), true
      assert_eq x.tag_match?('{dep*}'), true
      #
      assert_eq x.tag_match?('obsolete'), false
      assert_eq x.tag_match?('*ob*'), false
    end
    it "[!tjk7p] supports array of tag names." do
      x = Oktest::Node.new(nil, tag: ['exp', 'wip'])
      assert_eq x.tag_match?('exp'), true
      assert_eq x.tag_match?('wip'), true
      assert_eq x.tag_match?('{exp,wip}'), true
      assert_eq x.tag_match?('{foo,wip,bar}'), true
      #
      assert_eq x.tag_match?('foo*'), false
      assert_eq x.tag_match?('{foo,bar}'), false
    end
  end

  describe '#filter_children!()' do
    it "[!osoq2] can filter topics by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Hello', nil, nil)
      assert_eq uncolor(sout), expected
    end
    it "[!wzcco] can filter topics by pattern." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter('*832795*', nil, nil)
      assert_eq uncolor(sout), expected
    end
    it "[!mz6id] can filter nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter('*loat*', nil, nil)
      assert_eq uncolor(sout), expected
    end
    it "[!0kw9c] can filter specs by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'hello spec', nil)
      assert_eq uncolor(sout), expected
    end
    it "[!fd8wt] can filter specs by pattern." do
      expected = <<END
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter(nil, '*#5', nil)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, 'spec example*', nil)
      assert_eq uncolor(sout), expected
    end
    it "[!1jphf] can filter specs from nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #4
END
      sout = run_filter(nil, '*#4', nil)
      assert_eq uncolor(sout), expected
    end
    it "[!eirmu] can filter topics by tag name." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'exp')
      assert_eq uncolor(sout), expected
    end
    it "[!6sq7g] can filter specs by tag name." do
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #2
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'new')
      assert_eq uncolor(sout), expected
    end
    it "[!6to6n] can filter by multiple tag name." do
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, '{new,exp}')
      assert_eq uncolor(sout), expected
    end
    it "[!r6g6a] supports negative filter by topic." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Topic 832795', nil, nil, negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter('{Integer,Float}', nil, nil, negative: true)
      assert_eq uncolor(sout), expected
    end
    it "[!doozg] supports negative filter by spec." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, '*hello*', nil, negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'spec example #[1-5]', nil, negative: true)
      assert_eq uncolor(sout), expected
    end
    it "[!ntv44] supports negative filter by tag name." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter(nil, nil, 'new', negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
END
      sout = run_filter(nil, nil, 'exp', negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
END
      sout = run_filter(nil, nil, '{exp,new}', negative: true)
      assert_eq uncolor(sout), expected
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

  class DummyRunner1 < Oktest::Runner
    def run_scope(*args)
      @_args = args
    end
    attr_reader :_args
  end

  describe '#accept_runner()' do
    it "[!5mt5k] invokes 'run_topic()' method of runner." do
      r = DummyRunner1.new(nil)
      sc = Oktest::ScopeNode.new(nil, __FILE__)
      sc.accept_runner(r, 10, 20)
      assert_eq r._args, [sc, 10, 20]
    end
  end

end


class TopicNode_TC < TC

  class DummyRunner2 < Oktest::Runner
    def run_topic(*args)
      @_args = args
    end
    attr_reader :_args
  end

  def new_topic(target, tag: nil)
    return Oktest::TopicNode.new(nil, target, tag: tag)
  end

  describe '#accept_runner()' do
    it "[!og6l8] invokes '.run_topic()' object of runner." do
      r = DummyRunner2.new(nil)
      x = Oktest::TopicNode.new(nil, nil)
      x.accept_runner(r, 30, 40)
      assert_eq r._args, [x, 30, 40]
    end
  end

  describe '#filter_match?()' do
    it "[!650bv] returns true if pattern matched to topic target name." do
      to = new_topic('#foobar()')
      assert_eq to.filter_match?('#foobar()'), true
      assert_eq to.filter_match?('*foobar*'), true
      assert_eq to.filter_match?('{*foobar*}'), true
      assert_eq to.filter_match?('[.#]foobar()'), true
      #
      to = new_topic(Array)
      assert_eq to.filter_match?('Array'), true
      assert_eq to.filter_match?('[aA]rray'), true
    end
    it "[!24qgr] returns false if pattern not matched to topic target name." do
      to = new_topic('#foobar()')
      assert_eq to.filter_match?('foobar'), false
      assert_eq to.filter_match?('#foobar'), false
      assert_eq to.filter_match?('foobar()'), false
      assert_eq to.filter_match?('*barfoo*'), false
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
    Oktest::TOPLEVEL_SCOPES.clear()
  end

  describe 'Oktest.scope()' do
    it "[!vxoy1] creates new scope object." do
      x = Oktest.scope() { nil }
      assert_eq x.class, Oktest::ScopeNode
    end
    it "[!jmc4q] raises error when nested called." do
      x = 0
      begin               ; x = 1
        Oktest.scope do   ; x = 2
          Oktest.scope do ; x = 3
          end
        end
      rescue Exception => exc
        assert_eq exc.class, Oktest::OktestError
        assert_eq exc.message, "scope() and global_scope() are not nestable."
      else
        assert false, "Oktest::OktestError expected."
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      assert_eq x, 2
    end
    it "[!rsimc] registers scope object into TOPLEVEL_SCOPES." do
      assert Oktest::TOPLEVEL_SCOPES.empty?, "should be empty"
      so = Oktest.scope do
      end
      assert ! Oktest::TOPLEVEL_SCOPES.empty?, "should not be empty"
      assert_eq Oktest::TOPLEVEL_SCOPES, [so]
    end
  end

  describe '#global_scope()' do
    it "[!fcmt2] not create new scope object." do
      go1 = Oktest.global_scope() { nil }
      assert_eq go1.class, Oktest::ScopeNode
      go2 = Oktest.global_scope() { nil }
      assert_eq go2, go1
      assert_eq go2, Oktest::GLOBAL_SCOPE
    end
    it "[!flnpc] run block in the GLOBAL_SCOPE object." do
      Oktest.global_scope do
        fixture :tmp_37531 do
          {id: 37531}
        end
      end
      assert Oktest::GLOBAL_SCOPE.fixtures.key?(:tmp_37531)
      v = Oktest::GLOBAL_SCOPE.fixtures[:tmp_37531][0].call
      assert_eq v, {id: 37531}
    end
    it "[!pe0g2] raises error when nested called." do
      x = 0
      begin                      ; x = 1
        Oktest.global_scope do   ; x = 2
          Oktest.global_scope do ; x = 3
          end
        end
      rescue Exception => exc
        assert_eq exc.class, Oktest::OktestError
        assert_eq exc.message, "scope() and global_scope() are not nestable."
      else
        assert false, "Oktest::OktestError expected."
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      assert_eq x, 2
      #
      x = 0
      begin                      ; x = 1
        Oktest.scope do          ; x = 2
          Oktest.global_scope do ; x = 3
          end
        end
      rescue Exception => exc
        assert_eq exc.class, Oktest::OktestError
        assert_eq exc.message, "scope() and global_scope() are not nestable."
      else
        assert false, "Oktest::OktestError expected."
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      assert_eq x, 2
      #
      x = 0
      begin                    ; x = 1
        Oktest.global_scope do ; x = 2
          Oktest.scope do      ; x = 3
          end
        end
      rescue Exception => exc
        assert_eq exc.class, Oktest::OktestError
        assert_eq exc.message, "scope() and global_scope() are not nestable."
      else
        assert false, "Oktest::OktestError expected."
      ensure
        Oktest.module_eval { @_in_scope = false }
      end
      assert_eq x, 2
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
      assert_eq node.children.length, 1
      to = node.children[0]
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
      assert_eq node.children.length, 1
      to = node.children[0]
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
      to = node.children[0]
      assert_eq to.target, "When condition..."
    end
  end

  describe '#case_else()' do
    it "[!oww4b] returns topic object." do
      node = new_node_with() do
        case_else tag: "dev" do
        end
      end
      assert_eq node.children.length, 1
      to = node.children[0]
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
      assert_eq node.children.length, 1
      to = node.children[0]
      assert_eq to.class, Oktest::TopicNode
      assert_eq to.target, "Else"
    end
    it "[!hs1to] 1st parameter is optional." do
      node = new_node_with() do
        case_else "(x < 0)" do
        end
      end
      assert_eq node.children.length, 1
      to = node.children[0]
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
      assert_eq node.children.length, 1
      sp = node.children[0]
      assert_eq sp.class, Oktest::SpecLeaf
      assert_eq sp.desc, "example #1"
      assert_eq sp.tag, "exp"
      assert_eq sp._prefix, "-"
    end
    it "[!ala78] provides raising TodoException block if block not given." do
      node = new_node_with() do
        spec "example #3"
      end
      assert_eq node.children.length, 1
      sp = node.children[0]
      begin
        sp.block.call
      rescue Exception => exc
        assert_eq exc.class, Oktest::TodoException
        assert_eq exc.message, "not implemented yet"
      else
        assert false, "TodoException should be called."
      end
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
    Oktest::TOPLEVEL_SCOPES.clear()
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

  class DummyRunner3 < Oktest::Runner
    def run_spec(*args)
      @_args = args
    end
    attr_reader :_args
  end

  describe '#run_block_in_context_object()' do
    it "[!tssim] run spec block in text object." do
      to = Oktest::TopicNode.new(nil, 'Example')
      sp = Oktest::SpecLeaf.new("#sample 2") { @called = "<<29193>>" }
      ctx = to.new_context_object()
      assert_eq ctx.instance_variable_get('@called'), nil
      sp.run_block_in_context_object(ctx)
      assert_eq ctx.instance_variable_get('@called'), "<<29193>>"
    end
  end

  describe '#accept_runner()' do
    it "[!q9j3w] invokes 'run_spec()' method of runner." do
      r = DummyRunner3.new(nil)
      sp = new_spec_object()
      assert_eq sp.class, Oktest::SpecLeaf
      sp.accept_runner(r, 3, 4, 5)
      assert_eq r._args, [sp, 3, 4, 5]
    end
  end

  describe '#filter_match?()' do
    it "[!v3u3k] returns true if pattern matched to spec description." do
      sp = new_spec_object("sample #1")
      assert_eq sp.filter_match?('sample #1'), true
      assert_eq sp.filter_match?('sample*'), true
      assert_eq sp.filter_match?('*#1'), true
      assert_eq sp.filter_match?('{sample*}'), true
    end
    it "[!kmc5m] returns false if pattern not matched to spec description." do
      sp = new_spec_object("sample #1")
      assert_eq sp.filter_match?('sample'), false
      assert_eq sp.filter_match?('sample #2'), false
      assert_eq sp.filter_match?('#2'), false
    end
  end

  describe '#tag_match?()' do
    it "[!5besp] returns true if pattern matched to tag name." do
      sp = new_spec_object("sample #1", tag: "experiment")
      assert_eq sp.tag_match?('experiment'), true
      assert_eq sp.tag_match?('exp*'), true
      assert_eq sp.tag_match?('*exp*'), true
      assert_eq sp.tag_match?('{exp*,obso*}'), true
    end
    it "[!id88u] supports multiple tag names." do
      sp = new_spec_object("sample #1", tag: ['exp', 'wip'])
      assert_eq sp.tag_match?('exp'), true
      assert_eq sp.tag_match?('wip'), true
      assert_eq sp.tag_match?('{exp,wip}'), true
      assert_eq sp.tag_match?('{foo,wip,bar}'), true
      #
      assert_eq sp.tag_match?('foo'), false
      assert_eq sp.tag_match?('{foo,bar}'), false
    end
    it "[!lpaz2] returns false if spec object has no tags." do
      sp = new_spec_object("sample #1", tag: nil)
      assert_eq sp.tag_match?('*'), false
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
