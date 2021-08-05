# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class ScopeObject_TC < TC

  def setup()
  end

  def teardown()
    Oktest::TOPLEVEL_SCOPES.clear()
  end

  describe '#add_child()' do
    it "[!1fyk9] keeps children." do
      p = Oktest::ScopeObject.new
      c = Oktest::ScopeObject.new
      p.add_child(c)
      assert_eq p.children, [c]
    end
    it "[!prkgy] child object may be scope object, such as SpecObject." do
      p = Oktest::ScopeObject.new
      c = Oktest::SpecObject.new(nil, nil, nil, nil, nil)
      p.add_child(c)
      assert_eq p.children, [c]
    end
    it "[!on2s1] sets self as parent scope of child scope." do
      p = Oktest::ScopeObject.new
      c = Oktest::ScopeObject.new
      p.add_child(c)
      assert_eq c.parent, p
    end
    it "[!v4alp] error if child scope already has parent scope." do
      p = Oktest::ScopeObject.new
      c = Oktest::ScopeObject.new
      c.parent = p
      begin
        p.add_child(c)
      rescue => exc
        assert exc.is_a?(ArgumentError), "ArgumentError expected."
        assert_eq exc.message, "add_child(): can't add child scope which already belongs to other."
      end
    end
  end

  describe '#get_fixture_info()' do
    it "[!f0105] returns fixture info." do
      x = Oktest::ScopeObject.new
      x.fixtures[:foo] = ["block", [:a, :b], "file:123"]
      assert_eq x.get_fixture_info(:foo), ["block", [:a, :b], "file:123"]
    end
  end

  describe '#new_context()' do
    it "[!p271z] creates new context object." do
      x = Oktest::ScopeObject.new
      x._klass = Class.new
      ctx = x.new_context()
      assert_eq ctx.class, x._klass
    end
  end

  describe '#accept_runner()' do
    it "[!olckb] raises NotImplementedError." do
      x = Oktest::ScopeObject.new
      begin
        x.accept_runner(Oktest::Runner.new(nil))
      rescue Exception => exc
        assert_eq exc.class, NotImplementedError
        assert_eq exc.message, "Oktest::ScopeObject#accept_runner(): not implemented yet."
      else
        assert false, "NotImplementedError expected."
      end
    end
  end

  describe '#_repr()' do
    it "[!bt5j8] builds debug string." do
      p = Oktest::ScopeObject.new
      c = Oktest::ScopeObject.new
      p.add_child(c)
      expected = <<'END'
-
  @fixtures: \{\}
  -
    @fixtures: \{\}
    @parent: #<Oktest::ScopeObject:.*>
END
      result = p._repr()
      assert result =~ Regexp.compile('\A'+expected)
    end
  end

  describe '#@+' do
    it "[!tzorv] returns self." do
      x = Oktest::ScopeObject.new
      assert (+ x).equal?(x), "should be same"
    end
  end

end


class FileScopeObject_TC < TC

  class DummyRunner1 < Oktest::Runner
    def run_topic(*args)
      @_args = args
    end
    attr_reader :_args
  end

  describe '#accept_runner()' do
    it "[!5mt5k] invokes 'run_topic()' method of runner." do
      r = DummyRunner1.new(nil)
      x = Oktest::FileScopeObject.new
      x.accept_runner(r, 10, 20)
      assert_eq r._args, [x, 10, 20]
    end
  end

end


class TopicObject_TC < TC

  class DummyRunner2 < Oktest::Runner
    def run_topic(*args)
      @_args = args
    end
    attr_reader :_args
  end

  describe '#accept_runner()' do
    it "[!og6l8] invokes '.run_topic()' object of runner." do
      r = DummyRunner2.new(nil)
      x = Oktest::TopicObject.new(nil, nil)
      x.accept_runner(r, 30, 40)
      assert_eq r._args, [x, 30, 40]
    end
  end

  describe '#filter_match?()' do
    it "[!650bv] returns true if pattern matched to topic target name." do
      to = Oktest::TopicObject.new('#foobar()')
      assert_eq to.filter_match?('#foobar()'), true
      assert_eq to.filter_match?('*foobar*'), true
      assert_eq to.filter_match?('{*foobar*}'), true
      assert_eq to.filter_match?('[.#]foobar()'), true
      #
      to = Oktest::TopicObject.new(Array)
      assert_eq to.filter_match?('Array'), true
      assert_eq to.filter_match?('[aA]rray'), true
    end
    it "[!24qgr] returns false if pattern not matched to topic target name." do
      to = Oktest::TopicObject.new('#foobar()')
      assert_eq to.filter_match?('foobar'), false
      assert_eq to.filter_match?('#foobar'), false
      assert_eq to.filter_match?('foobar()'), false
      assert_eq to.filter_match?('*barfoo*'), false
    end
  end

  describe '#tag_match?()' do
    it "[!5kmcf] returns false if topic object has no tags." do
      to = Oktest::TopicObject.new('#foobar()')
      assert_eq to.tag_match?('*'), false
    end
    it "[!fmwfy] returns true if pattern matched to tag name." do
      to = Oktest::TopicObject.new('#foobar()', 'deprecated')
      assert_eq to.tag_match?('deprecated'), true
      assert_eq to.tag_match?('dep*'), true
      assert_eq to.tag_match?('{dep*}'), true
      #
      assert_eq to.tag_match?('obsolete'), false
      assert_eq to.tag_match?('*ob*'), false
    end
    it "[!tjk7p] supports array of tag names." do
      to = Oktest::TopicObject.new('#foobar()', ['exp', 'wip'])
      assert_eq to.tag_match?('exp'), true
      assert_eq to.tag_match?('wip'), true
      assert_eq to.tag_match?('{exp,wip}'), true
      assert_eq to.tag_match?('{foo,wip,bar}'), true
      #
      assert_eq to.tag_match?('foo*'), false
      assert_eq to.tag_match?('{foo,bar}'), false
    end
  end

end


class ScopeClassMethods_TC < TC

  def new_scope_object(&b)
    so = Oktest.__scope(1, &b)
    return so
  end

  describe '#fixture()' do
    it "[!8wfrq] registers fixture factory block." do
      lineno = __LINE__ + 2
      so = new_scope_object() do
        fixture :alice do
          {name: "alice"}
        end
      end
      assert_eq so.fixtures.length, 1
      assert    so.fixtures.key?(:alice), "key not registerd"
      assert    so.fixtures[:alice][0].is_a?(Proc), "block expected"
      assert_eq so.fixtures[:alice][1], nil
      assert    so.fixtures[:alice][2].start_with?("#{__FILE__}:#{lineno}:in ")
    end
    it "[!y3ks3] retrieves block parameter names." do
      so = new_scope_object() do
        fixture :bob do |x, y|
          {name: "bob"}
        end
      end
      assert_eq so.fixtures[:bob][1], [:x, :y]
    end
  end

  describe '#topic()' do
    it "[!0gfvq] creates new topic object." do
      so = new_scope_object() do
        topic Dir, tag: "exp" do
        end
      end
      assert_eq so.children.length, 1
      to = so.children[0]
      assert_eq to.class, Oktest::TopicObject
      assert_eq to.target, Dir
      assert_eq to.tag, "exp"
      assert_eq to._prefix, "*"
    end
  end

  describe '#case_when()' do
    it "[!g3cvh] returns topic object." do
      so = new_scope_object() do
        case_when "condition..." do
        end
      end
      assert_eq so.children.length, 1
      to = so.children[0]
      assert_eq to.class, Oktest::TopicObject
      assert_eq to.target, "When condition..."
      assert_eq to.tag, nil
      assert_eq to._prefix, "-"
    end
    it "[!ofw1i] target is a description starting with 'When '." do
      so = new_scope_object() do
        case_when "condition..." do
        end
      end
      to = so.children[0]
      assert_eq to.target, "When condition..."
    end
  end

  describe '#case_else()' do
    it "[!oww4b] returns topic object." do
      so = new_scope_object() do
        case_else tag: "dev" do
        end
      end
      assert_eq so.children.length, 1
      to = so.children[0]
      assert_eq to.class, Oktest::TopicObject
      assert_eq to.target, "Else"
      assert_eq to.tag, "dev"
      assert_eq to._prefix, "-"
    end
    it "[!j5gnp] target is a description which is 'Else'." do
      so = new_scope_object() do
        case_else do
        end
      end
      assert_eq so.children.length, 1
      to = so.children[0]
      assert_eq to.class, Oktest::TopicObject
      assert_eq to.target, "Else"
    end
    it "[!hs1to] 1st parameter is optional." do
      so = new_scope_object() do
        case_else "(x < 0)" do
        end
      end
      assert_eq so.children.length, 1
      to = so.children[0]
      assert_eq to.class, Oktest::TopicObject
      assert_eq to.target, "Else (x < 0)"
    end
  end

  describe '#scope()' do
    it "[!c8c8o] creates new spec object." do
      so = new_scope_object() do
        spec "example #1", tag: "exp" do
        end
      end
      assert_eq so.children.length, 1
      sp = so.children[0]
      assert_eq sp.class, Oktest::SpecObject
      assert_eq sp.desc, "example #1"
      assert_eq sp.tag, "exp"
      assert_eq sp.params, []
      assert_eq sp._prefix, "-"
    end
    it "[!ep8ya] collects block parameter names if block given." do
      so = new_scope_object() do
        spec "example #2", tag: "exp" do |alice, bob|
        end
      end
      assert_eq so.children.length, 1
      sp = so.children[0]
      assert_eq sp.params, [:alice, :bob]
    end
    it "[!ala78] provides raising TodoException block if block not given." do
      so = new_scope_object() do
        spec "example #3"
      end
      assert_eq so.children.length, 1
      sp = so.children[0]
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
      assert_eq x.class, Oktest::FileScopeObject
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
      assert_eq go1.class, Oktest::FileScopeObject
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


class SpecObject_TC < TC

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

  describe '#accept_runner()' do
    it "[!q9j3w] invokes 'run_spec()' method of runner." do
      r = DummyRunner3.new(nil)
      sp = new_spec_object()
      assert_eq sp.class, Oktest::SpecObject
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
