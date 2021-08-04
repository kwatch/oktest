# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Visitor_TC < TC

  class MyVisitor < Oktest::Visitor
    def on_topic(target, tag, depth)
      print "  " * depth
      case target
      when /^When (.*)$/  ; print "- case_when: $1"
      when /^Else$/       ; print "- case_else:"
      else                ; print "+ topic: #{target}"
      end
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

  def setup()
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
    Oktest::TOPLEVEL_SCOPES.clear()
  end

  it "visits topics and specs and calls callbacks." do
    expected = <<'END'
+ topic: Example
  + topic: Integer (tag: cls)
    - spec: 1+1 should be 2.
    - spec: 1-1 should be 0.
    - case_when: $1
      - spec: abs() returns sign-reversed value.
    - case_else:
      - spec: abs() returns positive value.
  + topic: Float (tag: cls)
    - spec: 1*1 should be 1. (tag: err)
    - spec: 1/1 should be 1. (tag: err)
END
    sout, serr = capture do
      MyVisitor.new.start()
    end
    assert_eq sout, expected
    assert_eq serr, ""
  end

  it "doesn't change Oktest::TOPLEVEL_SCOPES." do
    n = Oktest::TOPLEVEL_SCOPES.length
    sout, serr = capture do
      MyVisitor.new.start()
    end
    assert_eq Oktest::TOPLEVEL_SCOPES.length, n
  end

end
