# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest::Visitor
  extend NanoTest

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

  def self.test_subject(desc, &b)
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end


  test_target 'Oktest::Visitor#visit_spec()' do
    test_subject "[!9f7i9] do something on spec." do
      expected = <<'END'
spec: sample {
}
END
      sp = Oktest::SpecLeaf.new(nil, "sample")
      visitor = DummyVisitor0.new
      visitor.visit_spec(sp, 0, nil)
      test_eq visitor.log.join(), expected
    end
  end

  test_target 'Oktest::Visitor#visit_topic()' do
    test_subject "[!mu3fn] visits each child of topic." do
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
      test_eq visitor.log.join(), expected
    end
  end

  test_target 'Oktest::Visitor#visit_scope()' do
    test_subject "[!hebhz] visits each child scope." do
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
      test_eq visitor.log.join(), expected
    end
  end

  test_target 'Oktest::Visitor#start()' do
    test_subject "[!8h8qf] start visiting tree." do
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
      test_eq visitor.log.join(), expected
    end
  end

end


Object.new.instance_eval do   # Oktest::Traverser
  extend NanoTest

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

  def self.prepare()
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

  def self.test_subject(desc, &b)
    NanoTest.test_subject(desc, &b)
  ensure
    Oktest::THE_GLOBAL_SCOPE.clear_children()
  end


  test_target 'Oktest::Traverser#start()' do
    test_subject "[!5zonp] visits topics and specs and calls callbacks." do
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
      test_eq sout, expected
      test_eq serr, ""
    end
    test_subject "[!gkopz] doesn't change Oktest::THE_GLOBAL_SCOPE." do
      prepare()
      n = Oktest::THE_GLOBAL_SCOPE.each_child.to_a.length
      sout, serr = capture do
        MyTraverser.new.start()
      end
      test_eq Oktest::THE_GLOBAL_SCOPE.each_child.to_a.length, n
    end
  end

  test_target 'Oktest::Traverser#visit_scope()' do
    test_subject "[!ledj3] calls on_scope() callback on scope." do
      expected = <<'END'
* scope: test/visitor_test.rb
* scope: test/visitor_test.rb
END
      Oktest.scope do
      end
      Oktest.scope do
      end
      sout, serr = capture { MyTraverser.new.start() }
      test_eq sout, expected
      test_eq serr, ""
    end
  end

  test_target 'Oktest::Traverser#visit_topic()' do
    test_subject "[!x8r9w] calls on_topic() callback on topic." do
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
      test_eq sout, expected
      test_eq serr, ""
    end
    test_subject "[!qh0q3] calls on_case() callback on case_when or case_else." do
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
      test_eq sout, expected
      test_eq serr, ""
    end
  end

  test_target 'Oktest::Traverser#visit_spec()' do
    test_subject "[!41uyj] calls on_spec() callback." do
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
      test_eq sout, expected
      test_eq serr, ""
    end
  end

end
