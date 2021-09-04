# -*- coding: utf-8 -*-

###
### $Release: 1.0.2 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Visitor_TC < TC

  class DummyVisitor0 < Oktest::Visitor
    def initialize
      @log = []
    end
    attr_reader :log
    def visit_scope(spec, depth, parent)
      indent = depth >= 0 ? "  " * depth : ""
      @log << "#{indent}scope: #{spec.filename} {\n"
      super
      @log << "#{indent}}\n"
    end
    def visit_topic(topic, depth, parent)
      indent = depth >= 0 ? "  " * depth : ""
      @log << "#{indent}topic: #{topic.target} {\n"
      super
      @log << "#{indent}}\n"
    end
    def visit_spec(spec, depth, parent)
      indent = depth >= 0 ? "  " * depth : ""
      @log << "#{indent}spec: #{spec.desc} {\n"
      super
      @log << "#{indent}}\n"
    end
  end

  def prepare()
    Oktest.scope do
      topic 'Example1' do
        topic 'sample1-1' do
          spec("1+1 should be 2") { ok {1+1} == 2 }
          spec("1-1 should be 0") { ok {1-1} == 0 }
        end
      end
    end
  end

  def setup
  end

  def teardown
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end

  describe '#visit_spec()' do
    it "[!9f7i9] do something on spec." do
      expected = <<'END'
spec: sample {
}
END
      sp = Oktest::SpecLeaf.new(nil, "sample")
      visitor = DummyVisitor0.new
      visitor.visit_spec(sp, 0, nil)
      assert_eq visitor.log.join(), expected
    end
  end

  describe '#visit_topic()' do
    it "[!mu3fn] visits each child of topic." do
      expected = <<'END'
topic: example {
  spec: sample {
  }
}
END
      to = Oktest::TopicNode.new(nil, "example")
      sp = Oktest::SpecLeaf.new(to, "sample")
      visitor = DummyVisitor0.new
      visitor.visit_topic(to, 0, nil)
      assert_eq visitor.log.join(), expected
    end
  end

  describe '#visit_scope()' do
    it "[!hebhz] visits each child scope." do
      expected = <<'END'
scope: file.rb {
  topic: example {
  }
  spec: sample {
  }
}
END
      sc = Oktest::ScopeNode.new(nil, "file.rb")
      to = Oktest::TopicNode.new(sc, "example")
      sp = Oktest::SpecLeaf.new(sc, "sample")
      visitor = DummyVisitor0.new
      visitor.visit_scope(sc, 0, nil)
      assert_eq visitor.log.join(), expected
    end
  end

  describe '#start()' do
    it "[!8h8qf] start visiting tree." do
      expected = <<'END'
scope: test/visitor_test.rb {
  topic: Example1 {
    topic: sample1-1 {
      spec: 1+1 should be 2 {
      }
      spec: 1-1 should be 0 {
      }
    }
  }
}
END
      prepare()
      visitor = DummyVisitor0.new
      visitor.start()
      assert_eq visitor.log.join(), expected
    end
  end

end


class Traverser_TC < TC

  class MyTraverser < Oktest::Traverser
    def on_scope(filename, tag, depth)
      print "  " * depth if depth >= 0
      print "* scope: #{filename}"
      print " (tag: #{tag})" if tag
      print "\n"
      yield
    end
    def on_topic(target, tag, depth)
      print "  " * depth
      print "+ topic: #{target}"
      print " (tag: #{tag})" if tag
      print "\n"
      yield
    end
    def on_case(desc, tag, depth)
      print "  " * depth
      print "- case: #{desc}"
      print " (tag: #{tag})" if tag
      print "\n"
      yield
    end
    def on_spec(desc, tag, depth)
      print "  " * depth
      print "- spec: #{desc}"
      print " (tag: #{tag})" if tag
      print "\n"
    end
  end

  def prepare()
    Oktest.scope do
      topic 'Example' do
        topic Integer, tag: 'cls' do
          spec "1+1 should be 2." do ok {1+1} == 2 end
          spec "1-1 should be 0." do ok {1-1} == 0 end
          case_when 'negative...' do
            spec "abs() returns sign-reversed value." do ok {-3.abs()} == 3 end
          end
          case_else do
            spec "abs() returns positive value." do ok {4.abs()} == 4 end
          end
        end
        topic Float, tag: 'cls' do
          spec "1*1 should be 1.", tag: 'err' do ok {1*1} == 2 end   # fail
          spec "1/1 should be 1.", tag: 'err' do ok {1/0} == 1 end   # error
        end
      end
    end
  end

  def teardown()
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end


  describe '#start()' do
    it "[!5zonp] visits topics and specs and calls callbacks." do
      expected = <<'END'
* scope: test/visitor_test.rb
  + topic: Example
    + topic: Integer (tag: cls)
      - spec: 1+1 should be 2.
      - spec: 1-1 should be 0.
      - case: When negative...
        - spec: abs() returns sign-reversed value.
      - case: Else
        - spec: abs() returns positive value.
    + topic: Float (tag: cls)
      - spec: 1*1 should be 1. (tag: err)
      - spec: 1/1 should be 1. (tag: err)
END
      prepare()
      sout, serr = capture { MyTraverser.new.start() }
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!gkopz] doesn't change Oktest::THE_GLOBAL_SCOPE." do
      prepare()
      n = Oktest::THE_GLOBAL_SCOPE.each_child.to_a.length
      sout, serr = capture do
        MyTraverser.new.start()
      end
      assert_eq Oktest::THE_GLOBAL_SCOPE.each_child.to_a.length, n
    end
  end

  describe '#visit_scope()' do
    it "[!ledj3] calls on_scope() callback on scope." do
      expected = <<'END'
* scope: test/visitor_test.rb
* scope: test/visitor_test.rb
END
      Oktest.scope do
      end
      Oktest.scope do
      end
      sout, serr = capture { MyTraverser.new.start() }
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end

  describe '#visit_topic()' do
    it "[!x8r9w] calls on_topic() callback on topic." do
      expected = <<'END'
* scope: test/visitor_test.rb
  + topic: Parent
    + topic: Child
END
      Oktest.scope do
        topic 'Parent' do
          topic 'Child' do
          end
        end
      end
      sout, serr = capture { MyTraverser.new.start() }
      assert_eq sout, expected
      assert_eq serr, ""
    end
    it "[!qh0q3] calls on_case() callback on case_when or case_else." do
      expected = <<'END'
* scope: test/visitor_test.rb
  + topic: Parent
    - case: When some condition
    - case: Else
END
      Oktest.scope do
        topic 'Parent' do
          case_when 'some condition' do
          end
          case_else do
          end
        end
      end
      sout, serr = capture { MyTraverser.new.start() }
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end

  describe '#visit_spec()' do
    it "[!41uyj] calls on_spec() callback." do
      expected = <<'END'
* scope: test/visitor_test.rb
  + topic: Example
    - spec: sample #1
    - spec: sample #2
END
      Oktest.scope do
        topic 'Example' do
          spec "sample #1" do ok {1+1} == 2 end
          spec "sample #2" do ok {1-1} == 0 end
        end
      end
      sout, serr = capture { MyTraverser.new.start() }
      assert_eq sout, expected
      assert_eq serr, ""
    end
  end

end
